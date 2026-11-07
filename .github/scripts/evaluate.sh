#!/usr/bin/env bash
# Evaluates configurations of the flake in the current directory, without
# building anything, and prints each one's derivation path on its own line.
#
# It keeps going past a configuration that doesn't evaluate (its error is
# printed), so one run shows every one that's broken, and exits 1 at the end
# if any were.
#
# Usage: evaluate.sh <attr>...
#   for example: evaluate.sh nixosConfigurations.vps.config.system.build.toplevel
set -uo pipefail

failed=()
for attr in "$@"; do
  echo "Evaluating $attr" >&2
  if nix eval --option allow-import-from-derivation false --raw ".#$attr.drvPath"; then
    echo
  else
    failed+=("$attr")
  fi
done

if [ ${#failed[@]} -gt 0 ]; then
  echo >&2
  echo "${#failed[@]} of $# configurations don't evaluate:" >&2
  printf '  %s\n' "${failed[@]}" >&2
  exit 1
fi
