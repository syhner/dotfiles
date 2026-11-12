#!/usr/bin/env bash
# Checks formatting and shell scripts, with the tools pinned by flake.lock so
# they match what the machines run. Each check runs even if one before it
# failed, so one run shows every problem; it exits 1 if any did.
#
# Usage: lint.sh [nixfmt|shellcheck|actionlint]...  (every check by default)
set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit
failed=

nixfmt() {
  # not git-crypt's files (see .gitattributes), which are encrypted on CI
  git ls-files -z ':(attr:!filter)*.nix' |
    nix shell --inputs-from . nixpkgs-nixos#nixfmt -c xargs -0 nixfmt --check
}
shellcheck() {
  nix shell --inputs-from . nixpkgs-nixos#shellcheck -c shellcheck .github/scripts/*.sh
}
# with shellcheck, it also checks the workflows' run: scripts
actionlint() {
  nix shell --inputs-from . nixpkgs-nixos#actionlint nixpkgs-nixos#shellcheck -c actionlint
}

[ $# -gt 0 ] || set -- nixfmt shellcheck actionlint
for check in "$@"; do
  case $check in
    nixfmt | shellcheck | actionlint) ;;
    *)
      echo "No check is called $check." >&2
      exit 2
      ;;
  esac
  printf '\n== %s\n' "$check"
  "$check" || failed+=" $check"
done

if [ -n "$failed" ]; then
  echo "Failed:$failed" >&2
  exit 1
fi
