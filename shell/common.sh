nixswitch() {
  local flake="${HOME}/nix"
  local ran=false

  if command -v nixos-rebuild >/dev/null 2>&1; then
    sudo nixos-rebuild switch --flake "$flake" "$@"
    ran=true
  fi

  if command -v darwin-rebuild >/dev/null 2>&1; then
    sudo darwin-rebuild switch --flake "$flake" "$@"
    ran=true
  fi

  if command -v home-manager >/dev/null 2>&1; then
    home-manager switch --flake "$flake" "$@"
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
