
# syntax=docker/dockerfile:1

# Pinned by digest so the same Dockerfile always resolves to the same base
# layers. Upgrades are manual: verify a new ubuntu-24.04 digest, change it here,
# and let CI re-run the scan gate before relying on it.
#   curl -fsSI -H 'Accept: application/vnd.docker.distribution.manifest.list.v2+json' \
#     https://mcr.microsoft.com/v2/devcontainers/base/manifests/ubuntu-24.04 \
#     | grep -i docker-content-digest
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04@sha256:d94c97dd9cacf183d0a6fd12a8e87b526e9e928307674ae9c94139139c0c6eae

LABEL org.opencontainers.image.title="OCaml OPAM Dev Container"
LABEL org.opencontainers.image.description="Reusable OCaml development environment with OPAM"
LABEL org.opencontainers.image.source="https://github.com/yorodm/ocaml-opam-devcontainer"
LABEL org.opencontainers.image.licenses="MIT"

ARG DEBIAN_FRONTEND=noninteractive

# Toolchain versions
ARG OCAML_VERSION=5.5.2
# "latest" installs the newest stable opam release; set a version to pin it.
# Note: with "latest" the resolved version changes over time, so pin
# OCAML_VERSION/OPAM_VERSION for fully reproducible builds.
ARG OPAM_VERSION=latest
# Concurrent build jobs for opam, used only while building the image. Passed as
# a per-command environment variable (opam reads $OPAMJOBS as the default for
# its jobs setting; there is no OPAMDOWNLOADJOBS equivalent) instead of ENV, so
# it does not permanently cap parallelism for the user's own opam calls inside
# the finished container.
ARG OPAMJOBS=4

ENV OPAMYES=1
ENV OPAMROOT=/home/vscode/.opam

# Install system dependencies
USER root

# Keep update, upgrade and install in one layer: the package lists are removed
# at the end, so a separate `apt-get install` layer would have no index and fail
# with exit code 100.
#
# apt-get upgrade is intentional even though it costs reproducibility: the
# vulnerability gate only ignores *unfixed* findings, so an unpatched base image
# would fail the release. The digest pin above bounds the drift.
#
# bubblewrap is deliberately not installed: opam is initialized with
# --disable-sandboxing below. Re-add it if you re-enable sandboxing.
RUN apt-get update \
    && apt-get upgrade -y -o Dpkg::Options::="--force-confold" \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        m4 \
        pkg-config \
        unzip \
        xz-utils \
        rsync \
        libgmp-dev \
        libev-dev \
    && rm -rf /var/lib/apt/lists/*

# Install the requested opam binary directly from its GitHub release instead
# of running the installer script. Release assets are named
# opam-<version>-<arch>-linux.
RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "$ARCH" in \
        amd64) OPAM_ARCH=x86_64 ;; \
        arm64) OPAM_ARCH=arm64 ;; \
        *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;; \
    esac; \
    if [ -z "$OPAM_VERSION" ] || [ "$OPAM_VERSION" = "latest" ]; then \
        OPAM_TAG_URL="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/ocaml/opam/releases/latest)"; \
        OPAM_TAG_URL="${OPAM_TAG_URL%/}"; \
        OPAM_VERSION="${OPAM_TAG_URL##*/}"; \
    fi; \
    curl -fsSL \
        "https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/opam-${OPAM_VERSION}-${OPAM_ARCH}-linux" \
        -o /usr/local/bin/opam; \
    chmod +x /usr/local/bin/opam; \
    opam --version

# Switch to the non-root development user
USER vscode

WORKDIR /workspaces

# Initialize OPAM
RUN opam init --bare --disable-sandboxing -y

# Build the compiler in its own layer so changing the tool list below does not
# force a full OCaml rebuild. Clean up in this same layer: a later `opam clean`
# would only hide these files, not remove them from the image.
RUN OPAMJOBS="${OPAMJOBS}" opam switch create default "${OCAML_VERSION}" -y \
    && opam clean -s -c -y

# Install the development tools in a separate, cacheable layer.
# -a implies -s, and --logs has no short flag.
RUN OPAMJOBS="${OPAMJOBS}" opam install --switch=default -y \
        dune \
        ocaml-lsp-server \
        ocamlformat \
        utop \
        odoc \
        merlin \
    && opam clean -a -c --logs -y

# Make the selected switch available in every terminal
ENV OPAMSWITCH=default
ENV OPAM_SWITCH_PREFIX=/home/vscode/.opam/default
ENV PATH="/home/vscode/.opam/default/bin:${PATH}"

# Configure interactive Bash sessions
RUN echo 'eval "$(opam env --switch=default)"' >> /home/vscode/.bashrc

CMD ["/bin/bash"]
