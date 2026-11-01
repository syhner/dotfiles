# The nixpkgs a configuration uses, for its platform. It allows the unfree
# packages the configuration's modules name (see nix/modules.nix).
{
  inputs,
  platform,
  modules,
}:
let
  inherit (inputs.nixpkgs-nixos) lib;
  nixpkgs = if lib.hasSuffix "-darwin" platform then inputs.nixpkgs-darwin else inputs.nixpkgs-nixos;
  unfree = builtins.concatMap (module: module.unfree or [ ]) modules;
in
import nixpkgs {
  system = platform;
  config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfree;
  overlays = [
    (final: prev: {
      # namespace unstable packages under pkgs.unstable
      unstable = inputs.nixpkgs-unstable.legacyPackages.${platform};
    })
  ];
}
