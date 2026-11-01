# How every config builds nixpkgs, and installs the packages and fonts the
# selected modules list (see lib/modules.nix). Not a module a config opts into:
# modules rely on it (pkgs.unstable, unfree packages).
#
# Systems install system-wide. Standalone homes own nixpkgs, so they get it too
# (the nixpkgs option names are the same in Home Manager) and install through
# Home Manager. Integrated homes use the system's pkgs, so they don't get it.
{
  inputs,
  selected,
  standalone,
}:
{ pkgs, lib, ... }:
let
  available = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform);
  packages = available (selected.packages pkgs);
  fonts = available (selected.fonts pkgs);
in
{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) selected.unfree;

  nixpkgs.overlays = [
    (final: prev: {
      # namespace unstable packages under pkgs.unstable
      unstable = import inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
      };
    })
  ];
}
// (
  if standalone then
    {
      home.packages = packages ++ fonts;
      fonts.fontconfig.enable = lib.mkIf (fonts != [ ]) true;
    }
  else
    {
      environment.systemPackages = packages;
      fonts.packages = fonts;
    }
)
