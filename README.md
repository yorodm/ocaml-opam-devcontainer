OCaml + OPAM Dev Container

A reusable, containerized OCaml development environment powered by Ubuntu, OPAM, and Visual Studio Code Dev Containers.

Designed for local development, GitHub Codespaces, and reusable Docker-based development environments.

Features
Ubuntu 24.04 LTS
OCaml 5.5.2
OPAM latest stable
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
Automated container vulnerability scanning with Trivy
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
OPAM	latest stable
Dune	OPAM-resolved
OCaml LSP	OPAM-resolved
Merlin	OPAM-resolved
OCamlformat	OPAM-resolved
Utop	OPAM-resolved
Odoc	OPAM-resolved

OPAM defaults to the latest stable release; set the `OPAM_VERSION` build argument to pin a specific version.
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

Customize toolchain versions

The Dockerfile supports build arguments:

dockerfile
ARG OCAML_VERSION=5.5.2
ARG OPAM_VERSION=latest


You can change these values when building your own image. Set OPAM_VERSION to latest to install the newest stable release, or to a version such as 2.6.1 to pin it.

Reproducibility

The base image is pinned by digest and patched with `apt-get upgrade` during the build, and
`OPAM_VERSION` defaults to `latest`. The upgrade step is deliberate: the vulnerability gate
only ignores *unfixed* findings, so an unpatched base image would fail a release. For fully
reproducible builds, pin `OPAM_VERSION` to an exact version and build from the base image
digest you want frozen.

Build the image locally
bash
docker build \
  --build-arg OCAML_VERSION=5.5.2 \
  --build-arg OPAM_VERSION=latest \
  -t ocaml-opam-devcontainer:local .

Published images

Images are published automatically to GitHub Container Registry when a `v*` tag is pushed.

Versioning model

Git tags are the source of truth and must be annotated semver tags of the form
`vMAJOR.MINOR.PATCH`, optionally with a pre-release suffix such as `-rc.1`.

For a stable release `v1.4.2` the following image tags are published:

| Image tag | Type | Meaning |
| --- | --- | --- |
| `1.4.2` | immutable | This exact release. |
| `1.4` | moving | Latest patch release in the `1.4` line. |
| `1` | moving | Latest minor and patch release in the `1` line. |
| `latest` | moving | Latest stable release published from the default branch. |
| `sha-<short>` | immutable | Commit that produced the image. |

Rules:

- An `X.Y.Z` tag is never re-pointed. Only the moving tags (`X`, `X.Y`, `latest`) are
  re-pointed, and only after the vulnerability scan passes.
- Pre-release tags (`v1.5.0-rc.1`) publish only `1.5.0-rc.1` and `sha-<short>`. They never
  move `1.5`, `1`, or `latest`.
- `0.x` releases do not publish a moving `0` tag, because every `0.x` release may contain
  breaking changes. Use an exact `0.Y.Z` tag for pinning.
- `latest` is only published when the tagged commit is contained in the default branch, so
  a release tagged on a feature branch does not overwrite `latest`.
- `workflow_dispatch` never publishes `latest`.

Releasing

```bash
git tag -a v1.4.2 -m "Release 1.4.2"
git push origin v1.4.2
```

Architecture

The image is built for:

- `linux/amd64`
- `linux/arm64`

Each platform is built on a matching native GitHub-hosted runner (`ubuntu-latest` for
`linux/amd64` and `ubuntu-24.04-arm` for `linux/arm64`) and the two builds run in parallel.
Building arm64 under QEMU emulation makes the OCaml compiler build extremely slow, so
emulation is avoided entirely.

arm64 Linux runners are standard GitHub-hosted runners for public repositories, where they
are free and unlimited. A private copy or fork may not have access to them; in that case
remove the `linux/arm64` entry from the build matrix, or fall back to a single
`ubuntu-latest` job using `docker/setup-qemu-action` with both platforms in one build.

Build cache

Published builds store their build cache in the registry under the tags
`buildcache-linux-amd64` and `buildcache-linux-arm64`, one per platform so the parallel
builds never overwrite each other. Unlike the Actions cache, which is scoped to a git ref,
these cache tags are shared across tags and branches, so a versioned release can reuse
layers from earlier builds instead of recompiling from scratch. The cache tags are internal
to CI and are not meant to be pulled as images. Pull request builds read the amd64 cache tag
to stay warm, but never write to it.

Release pipeline

A publish run is split into four jobs:

1. `build` builds each platform on its native runner and pushes it to the registry by
digest, without publishing any tag.
2. `merge` combines those per-platform digests into one multi-arch image under a temporary
`staging` tag and records the merged digest.
3. `security-scan` scans exactly that digest and fails the run on findings.
4. `promote` creates the release tags, and only runs if the scan passed.

Because the promoted digest is the scanned digest, a release cannot slip an unscanned image
into a tag.

Security scanning

Images are scanned with Trivy by the `security-scan` composite action.

- On pull requests, the test workflow builds the image once per platform, scans the amd64
image, and posts the results as a single sticky comment.
- On release, the publish workflow scans the merged multi-arch image at the exact digest it
is about to promote, and only creates the release tags if the scan passes.

Scan policy: only `linux/amd64` is scanned. The amd64 image is treated as representative of
the release. This is a deliberate trade-off; if you need per-architecture assurance, scan
the arm64 image as well.

The scan fails the build for fixable `CRITICAL` and `HIGH` findings. Unfixed vulnerabilities
are ignored because they cannot be remediated. To accept a specific finding, add its ID to a
`.trivyignore` file at the repository root.

On pull requests, the scan updates a single sticky comment with the findings. Pull requests
from forks run with a read-only token, so their results are only available in the workflow
run summary.

The `staging` and `buildcache-*` tags are internal to CI and are overwritten on each
release. A release that fails the scan leaves its `staging` image in the registry; it is
never tagged as a release.

Dependency policy

Everything the pipeline consumes is pinned to an exact, well-known version and upgraded
manually, only when there is a reason to:

| Pinned item | Example value | How it is upgraded |
| --- | --- | --- |
| Actions | `actions/checkout@v7.0.1` | Change the ref, run CI, confirm green. |
| Trivy release | `trivy-version: v0.76.2` | Change the input; the download is checksum-verified. |
| Base image | `ubuntu-24.04@sha256:d94c97dd…` | Resolve a new digest (command in the Dockerfile) and change `FROM`. |
| OCaml / opam | `OCAML_VERSION=5.5.2`, `OPAM_VERSION=latest` | Edit the build argument. |

Refs are pinned to exact tags rather than floating majors deliberately: a `@v7` ref is
re-resolved to the newest `v7.x` on every run, so the code executing in the release gate
could change without any commit or review.

The one deliberate exception is `OPAM_VERSION=latest`, which resolves at build time. opam
release binaries ship a GPG signature rather than a checksum file, so pinning or verifying
them means trusting a signing key first; see the open question in `PLAN.md`.

Development

Contributions are welcome!

Please open an issue for bugs or feature requests and submit pull requests for improvements.

License

MIT License. See LICENSE.
