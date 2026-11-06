#!/usr/bin/env bash
# Evaluates configurations of the flake in the current directory, without
# building anything, and prints each one's derivation path on its own line.
#
# It evaluates as many at once as the machine has cores (one nix eval uses
# one), or $EVAL_JOBS. Each one's messages are printed after it's done, in the
# order given, so they don't interleave.
#
# It keeps going past a configuration that doesn't evaluate (its error is
# printed), so one run shows every one that's broken, and exits 1 at the end
# if any were.
#
# Usage: evaluate.sh <attr>...
#   for example: evaluate.sh nixosConfigurations.vps.config.system.build.toplevel
set -uo pipefail

jobs=${EVAL_JOBS:-$(getconf _NPROCESSORS_ONLN)}
dir=$(mktemp -d)

# Give xargs each configuration's position and attr, and it runs the sh
# script with them as $1 and $2 ($0 is the directory). It leaves the
# derivation path in <position>.drv, if it evaluates, and the messages in
# <position>.log. The evaluation cache is off: the evaluations would take
# turns writing to it, and a CI machine starts with it empty anyway.
i=0
# shellcheck disable=SC2016 # sh expands the $s in its script, not this one
for attr in "$@"; do
  printf '%s\0%s\0' "$i" "$attr"
  i=$((i + 1))
done |
  xargs -0 -n 2 -P "$jobs" sh -c '
    nix eval --no-eval-cache --option allow-import-from-derivation false --raw ".#$2.drvPath" \
      >"$0/$1.drv" 2>"$0/$1.log" || rm -f "$0/$1.drv"
  ' "$dir"

failed=()
i=0
for attr in "$@"; do
  echo "Evaluating $attr" >&2
  cat "$dir/$i.log" >&2
  if [ -f "$dir/$i.drv" ]; then
    cat "$dir/$i.drv"
    echo
  else
    failed+=("$attr")
  fi
  i=$((i + 1))
done
rm -rf "$dir"

if [ ${#failed[@]} -gt 0 ]; then
  echo >&2
  echo "${#failed[@]} of $# configurations don't evaluate:" >&2
  printf '  %s\n' "${failed[@]}" >&2
  exit 1
fi
