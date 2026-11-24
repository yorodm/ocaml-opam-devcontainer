# OCaml + OPAM Dev Container

A containerized OCaml development environment based on Ubuntu 24.04, OPAM, and the
[Dev Containers](https://containers.dev/) specification. Works locally, in GitHub Codespaces,
and as a prebuilt image from GitHub Container Registry.

## Features

- Ubuntu 24.04 LTS, OCaml 5.5.2, and the latest stable OPAM
- Dune, OCaml LSP, Merlin, OCamlformat, Utop, and Odoc
- Non-root `vscode` user
- `linux/amd64` and `linux/arm64` images

## Requirements

- Docker Desktop or Docker Engine
- Visual Studio Code with the
  [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
  extension

## Quick start

### Use this repository as a template

1. Click **Use this template** on GitHub.
2. Create your own repository and clone it.
3. Open the folder in Visual Studio Code.
4. Run **Dev Containers: Reopen in Container**.

The environment builds automatically.

### Use the published image

Add it to your project's `.devcontainer/devcontainer.json`:

```json
{
  "name": "OCaml Development",
  "image": "ghcr.io/yorodm/ocaml-opam-devcontainer:latest",
  "remoteUser": "vscode",
  "customizations": {
    "vscode": {
      "extensions": ["ocamllabs.ocaml-platform"]
    }
  }
}
```

### Run it directly

```bash
docker pull ghcr.io/yorodm/ocaml-opam-devcontainer:latest

# Try it
docker run --rm -it ghcr.io/yorodm/ocaml-opam-devcontainer:latest

# Or mount a project directory
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  ghcr.io/yorodm/ocaml-opam-devcontainer:latest
```

## Installed versions

| Component | Version |
| --- | --- |
| Ubuntu | 24.04 |
| OCaml | 5.5.2 |
| OPAM | latest stable |
| Dune, OCaml LSP, Merlin, OCamlformat, Utop, Odoc | resolved by OPAM |

Verify the toolchain inside the container:

```bash
ocaml --version
opam --version
dune --version
opam switch show
```

## Create a project

```bash
dune init project my-project
cd my-project
dune build
dune exec my_project
```

## Build the image

```bash
docker build \
  --build-arg OCAML_VERSION=5.5.2 \
  --build-arg OPAM_VERSION=latest \
  -t ocaml-opam-devcontainer:local .
```

| Build argument | Default | Description |
| --- | --- | --- |
| `OCAML_VERSION` | `5.5.2` | OCaml compiler version. |
| `OPAM_VERSION` | `latest` | OPAM release. Set a version such as `2.6.1` to pin it. |
| `OPAMJOBS` | `4` | Concurrent build jobs used while creating the image. |

## Image tags

New images are published when an annotated semver tag is pushed:

```bash
git tag -a v1.4.2 -m "Release 1.4.2"
git push origin v1.4.2
```

| Tag | Type | Meaning |
| --- | --- | --- |
| `1.4.2` | immutable | That exact release. |
| `1.4` | moving | Latest patch release in the `1.4` line. |
| `1` | moving | Latest release in the `1` line. |
| `latest` | moving | Latest stable release from the default branch. |
| `sha-<short>` | immutable | Commit that produced the image. |

- Pre-release tags (`v1.5.0-rc.1`) publish only `1.5.0-rc.1` and `sha-<short>`.
- `0.x` releases do not move a `0` tag.
- Moving tags only move after the vulnerability scan passes.

## Security

- Images are scanned with Trivy on pull requests and before release tags are created. Fixable
  `CRITICAL` and `HIGH` findings block a release; add an ID to `.trivyignore` to accept a
  specific finding.
- Only `linux/amd64` is scanned. It is treated as representative of the release.
- The `staging` and `buildcache-*` tags are internal to CI and should not be pulled.

## Development

Contributions are welcome: open an issue for bugs or feature requests, and submit pull
requests for improvements. Dependencies are pinned to exact versions and upgraded manually.

## License

MIT License. See [LICENSE](LICENSE).
