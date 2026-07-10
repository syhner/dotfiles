{
  inputs,
  pkgs,
  lib,
  cfg,
  ...
}:
let
  shared = import ./packages.nix {
    inherit
      inputs
      pkgs
      lib
      cfg
      ;
  };
in
{
  nixpkgs.config = shared.nixpkgsConfig;
  nixpkgs.overlays = shared.overlays;

  environment.systemPackages = shared.packages;
  fonts.packages = shared.fonts;
}
