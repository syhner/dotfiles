{
  inputs,
  pkgs,
  lib,
  type,
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
  home.packages = shared.packages ++ shared.fonts;
  fonts.fontconfig.enable = true;
}
// lib.optionalAttrs (type == "home-manager") {
  nixpkgs.config = shared.nixpkgsConfig;
  nixpkgs.overlays = shared.overlays;
}
