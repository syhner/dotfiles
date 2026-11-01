# Installs the packages and fonts the selected modules list (see
# lib/modules.nix): system-wide on NixOS and nix-darwin, and through Home
# Manager only when it runs standalone.
{
  packages,
  fonts,
  standalone,
}:
{ pkgs, lib, ... }:
let
  available = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform);
  selectedPackages = available (packages pkgs);
  selectedFonts = available (fonts pkgs);
in
if standalone then
  {
    home.packages = selectedPackages ++ selectedFonts;
    fonts.fontconfig.enable = lib.mkIf (selectedFonts != [ ]) true;
  }
else
  {
    environment.systemPackages = selectedPackages;
    fonts.packages = selectedFonts;
  }
