{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  shared = import ./packages.nix { inherit inputs pkgs lib; };
in
{
  nixpkgs.config = shared.nixpkgsConfig;
  nixpkgs.overlays = shared.overlays;

  environment.systemPackages = shared.packages;
  fonts.packages = shared.fonts;
}
