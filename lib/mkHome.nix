{
  inputs,
  system,
  modules ? [ ],
}:
let
  common = import ./common.nix {
    inherit
      inputs
      system
      modules
      ;
  };

  # Standalone Home Manager owns nixpkgs; integrated homes use the system's pkgs.
  packageModule =
    { pkgs, lib, ... }:
    let
      shared = import ../modules/packages/packages.nix {
        inherit inputs pkgs lib;
        inherit (common.modules) enabled;
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
  modules = [
    ../home.nix
  ]
  ++ common.modules.home
  ++ common.nixpkgs.lib.optional common.modules.enabled.packages packageModule;
}
