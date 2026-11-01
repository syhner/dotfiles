{
  inputs,
  system,
  defaultModuleBehaviour ? true,
  features ? { },
  extraHomeModules ? [ ],
}:
let
  common = import ./common.nix {
    inherit
      inputs
      system
      defaultModuleBehaviour
      features
      ;
  };
  moduleLists = import ./modules.nix {
    lib = common.nixpkgs.lib;
    features = common.features;
    inherit extraHomeModules;
  };

  # Standalone Home Manager owns nixpkgs; integrated homes use the system's pkgs.
  packageModule =
    { pkgs, lib, ... }:
    let
      shared = import ../modules/packages/packages.nix {
        inherit inputs pkgs lib;
        features = common.features;
      };
    in
    {
      nixpkgs.config = shared.nixpkgsConfig;
      nixpkgs.overlays = shared.overlays;
    };
in
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = common.nixpkgs.legacyPackages.${system};
  extraSpecialArgs = common.specialArgs // {
    systemKey = "home";
  };
  modules =
    moduleLists.homeModules
    ++ common.nixpkgs.lib.optional (
      common.features.modules.home && common.features.packages
    ) packageModule;
}
