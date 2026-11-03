{
  darwin,
  pkgs,
  repositoryPath,
  ...
}:
{
  tags = [ "workstation" ];

  packages = [
    # nixpkgs can't build the macOS app, so it repackages the official one.
    (if darwin then pkgs.ghostty-bin else pkgs.ghostty)
  ];

  home =
    { config, ... }:
    {
      home.file.".config/ghostty/config".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/ghostty/config";
    };
}
