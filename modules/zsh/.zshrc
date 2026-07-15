export EDITOR=vim

# enable vi mode (default )
bindkey -v
# make escaping to normal mode instant
KEYTIMEOUT=1
# in vi insert/cmd mode, fix cmd/option + left/right navigation
for keymap in viins vicmd; do
  # cmd + left/right
  bindkey -M "$keymap" '^A' beginning-of-line
  bindkey -M "$keymap" '^E' end-of-line

  # option + left/right
  bindkey -M "$keymap" $'\eb' backward-word
  bindkey -M "$keymap" $'\ef' forward-word
done

nixswitch() {
  local flakeDir="${HOME}/dotfiles"
  local ran=false

  if command -v nixos-rebuild >/dev/null 2>&1; then
    sudo nixos-rebuild switch --flake "$flakeDir" "$@"
    ran=true
  fi

  if command -v darwin-rebuild >/dev/null 2>&1; then
    sudo darwin-rebuild switch --flake "$flakeDir" "$@"
    ran=true
  fi

  # this will only run if nixos-rebuild or darwin-rebuild don't already run home manager as a system module, since the home-manager CLI is not available after those rebuilds
  if command -v home-manager >/dev/null 2>&1; then
    home-manager switch --flake "$flakeDir" "$@"
    ran=true
  fi

  if [ "$ran" = false ]; then
    echo "No supported Nix rebuild command found (nixos-rebuild, darwin-rebuild, home-manager)"
    return 1
  fi
}

bak() {
  local keep=0

  while [ $# -gt 0 ]; do
    case "$1" in
      -k|--keep)
        keep=1
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo "bak: unknown option '$1'" >&2
        return 1
        ;;
      *)
        break
        ;;
    esac
  done

  if [ $# -ne 1 ]; then
    echo "usage: bak [-k|--keep] <path to file>" >&2
    return 1
  fi

  local src="$1"

  if [ ! -e "$src" ]; then
    echo "bak: '$src' does not exist" >&2
    return 1
  fi

  local n=1
  while [ -e "${src}.bak-${n}" ]; do
    n=$((n + 1))
  done

  local dst="${src}.bak-${n}"

  if [ "$keep" -eq 1 ]; then
    cp -a -- "$src" "$dst"
    echo "copied '$src' -> '$dst'"
  else
    mv -- "$src" "$dst"
    echo "moved '$src' -> '$dst'"
  fi
}
