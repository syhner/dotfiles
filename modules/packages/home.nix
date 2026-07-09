{
  inputs,
  pkgs,
  lib,
  type,
  ...
}:
let
  shared = import ./packages.nix { inherit inputs pkgs lib; };
in
{
  home.packages = shared.packages ++ shared.fonts;
  fonts.fontconfig.enable = true;
}
// lib.optionalAttrs (type == "home-manager") {
  nixpkgs.config = shared.nixpkgsConfig;
  nixpkgs.overlays = shared.overlays;
}
