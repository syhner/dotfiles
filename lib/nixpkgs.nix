# How every config builds nixpkgs. Not a module a config opts into: it installs
# nothing, and modules rely on it (pkgs.unstable, unfree packages).
#
# The option names are the same in NixOS, nix-darwin and Home Manager, so this
# works for systems and for standalone homes. Integrated homes use the system's
# pkgs, so they don't get it.
{
  inputs,
  # Unfree package names the selected modules allow (see lib/modules.nix).
  unfree,
}:
{ lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfree;

  nixpkgs.overlays = [
    (final: prev: {
      # namespace unstable packages under pkgs.unstable
      unstable = import inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
      };
    })
  ];
}
