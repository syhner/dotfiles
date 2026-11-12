#!/usr/bin/env bash
# Runs what .github/workflows/ci.yml does, on this machine: for each platform,
# evaluates its configurations and lists what no cache has, then the lint
# checks. Each step runs even if one before it failed, so one run shows every
# problem.
#
# It builds only with --build, and never pushes to the cache. What CI builds
# on the fleet's builders goes to this machine's (see features/fleet-builders).
# It reads the working tree, uncommitted changes included.
#
# Usage: ci-local.sh [--build] [platform]...
#   for example: ci-local.sh --build x86_64-linux
set -euo pipefail

build=
if [ "${1:-}" = --build ]; then
  build=1
  shift
fi
cd "$(git rev-parse --show-toplevel)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=

step() {
  printf '\n== %s\n' "$1"
}

step plan
nix eval --option allow-import-from-derivation false --json .#ci >"$tmp/ci.json"
platforms=${*:-$(jq -r '.platforms[].platform' "$tmp/ci.json")}
export UNFREE
UNFREE=$(jq -r .unfree "$tmp/ci.json")

for platform in $platforms; do
  step "build $platform"
  jq -r --arg platform "$platform" '.platforms[] | select(.platform == $platform) | .attrs[]' \
    "$tmp/ci.json" >"$tmp/attrs.txt"
  if [ ! -s "$tmp/attrs.txt" ]; then
    echo "No configurations are for $platform." >&2
    failed+=" $platform"
    continue
  fi
  # like CI, it builds what did evaluate even if some didn't
  ok=1
  xargs .github/scripts/evaluate.sh <"$tmp/attrs.txt" >"$tmp/drvs.txt" || ok=
  if [ -n "$build" ]; then
    xargs .github/scripts/build-uncached.sh <"$tmp/drvs.txt" || ok=
  else
    xargs .github/scripts/build-uncached.sh --dry-run <"$tmp/drvs.txt" || ok=
  fi
  [ -n "$ok" ] || failed+=" $platform"
done

.github/scripts/lint.sh || failed+=" lint"

echo
if [ -n "$failed" ]; then
  echo "Failed:$failed" >&2
  exit 1
fi
echo "All passed."
