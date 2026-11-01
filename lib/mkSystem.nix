{
  inputs,
  system,
  hostname,
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
  systemKey = if common.isDarwin then "darwin" else "nixos";
  specialArgs = common.specialArgs // {
    inherit hostname systemKey;
  };

  homeManagerModule = {
    imports = [ inputs.home-manager."${systemKey}Modules".home-manager ];
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = specialArgs;
    home-manager.users.${common.username} = {
      imports = [ ../home.nix ] ++ common.modules.home;
    };
  };

  systemArgs = {
    inherit system specialArgs;
    modules = [
      ../hosts/${hostname}/configuration.nix
      homeManagerModule
    ]
    ++ common.modules.system;
  };
in
if common.isDarwin then
  inputs.nix-darwin.lib.darwinSystem systemArgs
else
  inputs.nixpkgs-nixos.lib.nixosSystem systemArgs
