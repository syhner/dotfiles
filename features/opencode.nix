{ pkgs, ... }:
{
  tags = [ "dev" ];
  # The stable release, which cache.nixos.org has. nixpkgs-unstable's opencode
  # 2.2.5 has a node_modules hash that doesn't match what bun produces, so it
  # fails to build. Go back to unstable once
  # https://github.com/NixOS/nixpkgs/pull/582675 reaches nixpkgs-unstable.
  packages = [ pkgs.opencode ];
}
