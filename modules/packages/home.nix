{
  inputs,
  pkgs,
  lib,
  features,
  ...
}:
let
  shared = import ./packages.nix {
    inherit
      inputs
      pkgs
      lib
      features
      ;
  };
in
{
  home.packages = shared.packages ++ shared.fonts;
  fonts.fontconfig.enable = true;
}
