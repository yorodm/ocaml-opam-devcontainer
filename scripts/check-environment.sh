
#!/usr/bin/env bash

set -euo pipefail

echo "Checking OCaml development environment..."

command -v ocaml
command -v opam
command -v dune

echo
echo "OCaml:"
ocaml --version

echo
echo "OPAM:"
opam --version

echo
echo "Active switch:"
opam switch show

echo
echo "Installed development tools:"
opam list --installed --short

echo
echo "Environment check completed successfully!"
