{
  inputs,
  system,
  hostname,
  defaultModuleBehaviour ? true,
  features ? { },
  extraHomeModules ? [ ],
  extraSystemModules ? [ ],
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
  systemKey = if common.isDarwin then "darwin" else "nixos";
  specialArgs = common.specialArgs // {
    inherit hostname systemKey;
  };
  moduleLists = import ./modules.nix {
    lib = common.nixpkgs.lib;
    features = common.features;
    inherit
      hostname
      homeManagerModule
      extraHomeModules
      extraSystemModules
      ;
  };

  homeManagerModule = {
    imports = [ inputs.home-manager."${systemKey}Modules".home-manager ];
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = specialArgs;
    home-manager.users.${common.username} = {
      imports = moduleLists.homeModules;
    };
  };

  systemArgs = {
    inherit system specialArgs;
    modules = moduleLists.systemModules;
  };
in
if common.isDarwin then
  inputs.nix-darwin.lib.darwinSystem systemArgs
else
  inputs.nixpkgs-nixos.lib.nixosSystem systemArgs
