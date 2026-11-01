{
  inputs,
  pkgs,
  lib,
  enabled,
  ...
}:
let
  shared = import ./packages.nix {
    inherit
      inputs
      pkgs
      lib
      enabled
      ;
  };
in
{
  nixpkgs.config = shared.nixpkgsConfig;
  nixpkgs.overlays = shared.overlays;

  environment.systemPackages = shared.packages;
  fonts.packages = shared.fonts;
}
