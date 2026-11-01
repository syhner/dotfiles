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
in
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = common.nixpkgs.legacyPackages.${system};
  extraSpecialArgs = common.specialArgs // {
    systemKey = "home";
  };
  modules = [
    ../home.nix
    # Standalone Home Manager owns nixpkgs; integrated homes use the system's pkgs.
    (import ./nixpkgs.nix {
      inherit inputs;
      inherit (common.modules) unfree;
    })
    (import ./packages.nix {
      inherit (common.modules) packages fonts;
      standalone = true;
    })
  ]
  ++ common.modules.home;
}
