OCaml + OPAM Dev Container

A reusable, containerized OCaml development environment powered by Ubuntu, OPAM, and Visual Studio Code Dev Containers.

Designed for local development, GitHub Codespaces, and reusable Docker-based development environments.

Features
Ubuntu 24.04 LTS
OCaml 5.5.2
OPAM 2.6.1
Dune
OCaml Language Server
Merlin
OCamlformat
Utop
Odoc
Non-root development user
Multi-platform Docker images (AMD64 and ARM64)
GitHub Actions automated builds
Published Docker image on GitHub Container Registry
Quick start
Requirements
Docker Desktop or Docker Engine
Visual Studio Code
Visual Studio Code Dev Containers extension
Option 1: Use this repository as a template
Click Use this template on GitHub.
Create your own repository.
Clone your new repository.
Open it in Visual Studio Code.
Run Dev Containers: Reopen in Container.

The development environment will be built automatically.

Option 2: Use the published Docker image

You can use the prebuilt image in your own project's .devcontainer/devcontainer.json:

json
{
  "name": "OCaml Development",
  "image": "ghcr.io/OWNER/ocaml-opam-devcontainer:latest",
  "remoteUser": "vscode",
  "customizations": {
    "vscode": {
      "extensions": [
        "ocamllabs.ocaml-platform"
      ]
    }
  }
}


Replace OWNER with the GitHub account or organization that publishes the image.

Option 3: Run the Docker image directly
bash
docker pull ghcr.io/OWNER/ocaml-opam-devcontainer:latest

bash
docker run --rm -it \
  ghcr.io/OWNER/ocaml-opam-devcontainer:latest


For a persistent development workspace, mount your project directory:

bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  ghcr.io/OWNER/ocaml-opam-devcontainer:latest

Installed versions
Component	Version
Ubuntu	24.04
OCaml	5.5.2
OPAM	2.6.1
Dune	OPAM-resolved
OCaml LSP	OPAM-resolved
Merlin	OPAM-resolved
OCamlformat	OPAM-resolved
Utop	OPAM-resolved
Odoc	OPAM-resolved
Verify your installation
bash
ocaml --version
opam --version
dune --version
opam switch show

Create an OCaml project
bash
dune init project my-project
cd my-project
dune build


Run the application:

bash
dune exec my_project

Customize compiler versions

The Dockerfile supports build arguments:

dockerfile
ARG OPAM_VERSION=2.6.1
ARG OCAML_VERSION=5.5.2


You can change these values when building your own image.

Build the image locally
bash
docker build \
  --build-arg OCAML_VERSION=5.5.2 \
  --build-arg OPAM_VERSION=2.6.1 \
  -t ocaml-opam-devcontainer:local .

Published images

Images are published automatically to GitHub Container Registry.

Available tags:

latest — latest build from the default branch.
vX.Y.Z — versioned release.
sha-... — commit-specific build.
Architecture

The image is built for:

linux/amd64
linux/arm64
Development

Contributions are welcome!

Please open an issue for bugs or feature requests and submit pull requests for improvements.

License

MIT License. See LICENSE.
