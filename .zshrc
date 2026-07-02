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
