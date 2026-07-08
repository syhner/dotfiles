{
  inputs,
  username,
  homeManager,
  repositoryPath,
  kernel,
  systemKey,
  ...
}:
if homeManager == "system-module" && (kernel == "linux" || kernel == "darwin") then
  {
    imports = [
      inputs.home-manager."${systemKey}Modules".home-manager
    ];

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = {
      inherit
        inputs
        username
        homeManager
        repositoryPath
        kernel
        systemKey
        ;
    };
    home-manager.users.${username} = ../../home.nix;
  }
else
  { }
