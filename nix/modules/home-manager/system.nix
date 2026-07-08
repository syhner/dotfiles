{
  inputs,
  platform,
  username,
  homeManagerStandalone,
  ...
}:
if !homeManagerStandalone && (platform == "nixos" || platform == "darwin") then
  {
    imports = [
      inputs.home-manager."${platform}Modules".home-manager
    ];

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = {
      inherit inputs username;
    };
    home-manager.users.${username} = ../../home.nix;
  }
else
  { }
