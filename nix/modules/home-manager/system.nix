{
  inputs,
  platform,
  username,
  homeManagerStandalone,
  repositoryPath,
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
      inherit
        inputs
        username
        platform
        homeManagerStandalone
        repositoryPath
        ;
    };
    home-manager.users.${username} = ../../home.nix;
  }
else
  { }
