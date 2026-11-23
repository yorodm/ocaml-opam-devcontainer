
# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

LABEL org.opencontainers.image.title="OCaml OPAM Dev Container"
LABEL org.opencontainers.image.description="Reusable OCaml development environment with OPAM"
LABEL org.opencontainers.image.source="https://github.com/yorodm/ocaml-opam-devcontainer"
LABEL org.opencontainers.image.licenses="MIT"

ARG DEBIAN_FRONTEND=noninteractive

# Toolchain versions
ARG OCAML_VERSION=5.5.2
# "latest" installs the newest stable opam release; set a version to pin it.
ARG OPAM_VERSION=latest
# Parallelism for opam builds/downloads (GitHub-hosted runners have 4 vCPUs).
ARG OPAMJOBS=4
ARG OPAMDOWNLOADJOBS=4

ENV OPAMYES=1
ENV OPAMROOT=/home/vscode/.opam

# Install system dependencies
USER root

# Keep update, upgrade and install in one layer: the package lists are removed
# at the end, so a separate `apt-get install` layer would have no index and fail
# with exit code 100.
RUN apt-get update \
    && apt-get upgrade -y -o Dpkg::Options::="--force-confold" \
    && apt-get install -y --no-install-recommends \
        build-essential \
        bubblewrap \
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
# force a full OCaml rebuild.
RUN opam switch create default "${OCAML_VERSION}" -y \
    && opam clean -s -y

# Install the development tools in a separate, cacheable layer
RUN opam install --switch=default -y \
        dune \
        ocaml-lsp-server \
        ocamlformat \
        utop \
        odoc \
        merlin \
    && opam clean -a -c -s -y

# Make the selected switch available in every terminal
ENV OPAMSWITCH=default
ENV OPAM_SWITCH_PREFIX=/home/vscode/.opam/default
ENV PATH="/home/vscode/.opam/default/bin:${PATH}"

# Configure interactive Bash sessions
RUN echo 'eval "$(opam env --switch=default)"' >> /home/vscode/.bashrc

CMD ["/bin/bash"]
