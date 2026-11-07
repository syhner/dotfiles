#!/usr/bin/env bash
# Evaluates configurations of the flake in the current directory, without
# building anything, and prints each one's derivation path on its own line.
#
# nix-eval-jobs evaluates them in parallel, one worker per core, or
# $EVAL_JOBS. It keeps going past a configuration that doesn't evaluate (its
# error is printed), so one run shows every one that's broken, and exits 1
# at the end if any were.
#
# Usage: evaluate.sh <attr>...
#   for example: evaluate.sh nixosConfigurations.vps.config.system.build.toplevel
set -euo pipefail

workers=${EVAL_JOBS:-$(getconf _NPROCESSORS_ONLN)}
results=$(mktemp)

# An attribute set with each configuration under its own attr, e.g.
# { "nixosConfigurations.vps...toplevel" = flake.nixosConfigurations.vps...toplevel; }
jobs=
for attr in "$@"; do
  jobs+="\"$attr\" = flake.$attr; "
done

nix run --inputs-from . nixpkgs-nixos#nix-eval-jobs -- \
  --workers "$workers" \
  --option allow-import-from-derivation false \
  --expr "let flake = builtins.getFlake \"git+file://$PWD\"; in { $jobs}" \
  >"$results"

# nix-eval-jobs has printed the errors already.
jq -r 'select(.drvPath) | .drvPath' "$results"

failed=$(jq -s 'map(select(.error)) | length' "$results")
if [ "$failed" -gt 0 ]; then
  echo >&2
  echo "$failed of $# configurations don't evaluate:" >&2
  jq -r 'select(.error) | "  " + (.attrPath | join("."))' "$results" >&2
  exit 1
fi
