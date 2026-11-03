{
  pkgs,
  platform,
  repositoryPath,
  ...
}:
{
  tags = [ "workstation" ];

  packages = [
    # nixpkgs can't build the macOS app, so it repackages the official one.
    (if platform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty)
  ];

  home =
    { config, ... }:
    {
      home.file.".config/ghostty/config".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/ghostty/config";
    };
}
