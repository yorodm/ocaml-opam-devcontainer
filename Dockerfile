
# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

LABEL org.opencontainers.image.title="OCaml OPAM Dev Container"
LABEL org.opencontainers.image.description="Reusable OCaml development environment with OPAM"
LABEL org.opencontainers.image.source="https://github.com/yorodm/ocaml-opam-devcontainer"
LABEL org.opencontainers.image.licenses="MIT"

ARG DEBIAN_FRONTEND=noninteractive

# Toolchain versions
ARG OPAM_VERSION=2.6.1
ARG OCAML_VERSION=5.5.2

ENV OPAMYES=1
ENV OPAMROOT=/home/vscode/.opam

# Install system dependencies
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
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

# Install a pinned OPAM binary
RUN bash -c \
    'sh <(curl -fsSL https://opam.ocaml.org/install.sh) --version "${OPAM_VERSION}"'

# Switch to the non-root development user
USER vscode

WORKDIR /workspaces

# Initialize OPAM and install OCaml
RUN opam init --bare --disable-sandboxing -y \
    && opam switch create default "${OCAML_VERSION}" -y \
    && opam install --switch=default -y \
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
