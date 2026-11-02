# The nixpkgs a configuration uses, for its platform, with unstable packages
# under pkgs.unstable. Both allow the unfree packages the configuration's modules
# name (see nix/modules.nix).
{
  inputs,
  platform,
  darwin,
  modules,
}:
let
  inherit (inputs.nixpkgs-nixos) lib;
  nixpkgs = if darwin then inputs.nixpkgs-darwin else inputs.nixpkgs-nixos;
  unfree = builtins.concatMap (module: module.unfree or [ ]) modules;
  config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfree;
in
import nixpkgs {
  system = platform;
  inherit config;
  overlays = [
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = platform;
        inherit config;
      };
    })
  ];
}
