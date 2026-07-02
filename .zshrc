nixswitch() {
  local flake="${HOME}/nix"

  if command -v nixos-rebuild >/dev/null 2>&1; then
    sudo nixos-rebuild switch --flake "$flake" "$@"

  elif command -v darwin-rebuild >/dev/null 2>&1; then
    sudo darwin-rebuild switch --flake "$flake" "$@"

  elif command -v home-manager >/dev/null 2>&1; then
    home-manager switch --flake "$flake" "$@"

  else
    echo "No supported Nix rebuild command found (nixos-rebuild, darwin-rebuild, home-manager)"
    return 1
  fi
}
