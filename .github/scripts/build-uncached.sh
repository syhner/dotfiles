#!/usr/bin/env bash
# Builds what some configurations need that no binary cache has, without
# assembling the configurations themselves. Given several, it builds what they
# share once.
#
# Assembling (the system profile, Home Manager's files, the top-level system)
# only links packages together, but it needs every one of them in the store,
# so it would download the whole system. Skipping it downloads only what the
# uncached packages need to build. What it gives up is the check that the
# packages assemble, for example that two of them don't install the same file.
#
# It leaves out the unfree packages too: everything whose name matches the
# regex in $UNFREE.
#
# Usage: build-uncached.sh [--dry-run] <derivation>...
set -euo pipefail

dry_run=
if [ "${1:-}" = --dry-run ]; then
  dry_run=1
  shift
fi
if [ $# -eq 0 ]; then
  echo "No derivations to build." >&2
  exit 0
fi
unfree=${UNFREE:-}
cd "$(mktemp -d)"

# Every derivation that would have to be built, rather than downloaded: the
# .drv paths listed under "will be built:", up to the next list's header
# (another unindented line ending in a colon), so a warning in between
# doesn't end the list early.
nix-store --realise --dry-run "$@" 2>dry-run.txt
awk '
  /will be built:$/ { built = 1; next }
  /^[^ ].*:$/ { built = 0 }
  built && $1 ~ /^\/nix\/store\/.+\.drv$/ { print $1 }
' dry-run.txt >uncached.txt

# Of those, leave out the assembly: derivations that are only built locally
# and aren't a package (they have no pname). Leave out the unfree packages
# too. Nix still builds whatever the rest depend on.
if [ -s uncached.txt ]; then
  xargs nix derivation show <uncached.txt |
    jq -r --arg unfree "$unfree" '
      (.derivations // .)
      | to_entries[]
      | ((.value.structuredAttrs // {}) + (.value.env // {})) as $attrs
      | select(
          $attrs.pname == null
          and ($attrs.preferLocalBuild // false | tostring | test("^(true|1)$"))
          | not
        )
      | select($unfree == "" or ((.value.name // $attrs.name) | test($unfree) | not))
      | if (.key | startswith("/")) then .key else "/nix/store/" + .key end
    ' |
    sort -u >to-build.txt
else
  : >to-build.txt
fi

echo "$(wc -l <uncached.txt | tr -d " ") derivations aren't in a cache; building $(wc -l <to-build.txt | tr -d " ") of them:"
sed -E 's|^/nix/store/[a-z0-9]{32}-||; s|\.drv$||; s|^|  |' to-build.txt

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### Built ($(wc -l <to-build.txt | tr -d " ") of $(wc -l <uncached.txt | tr -d " ") uncached derivations)"
    sed -E 's|^/nix/store/[a-z0-9]{32}-||; s|\.drv$||; s|^|- |' to-build.txt
  } >>"$GITHUB_STEP_SUMMARY"
fi

if [ -n "$dry_run" ] || [ ! -s to-build.txt ]; then
  exit 0
fi

sed 's/$/^*/' to-build.txt | xargs nix build --no-link --print-build-logs
