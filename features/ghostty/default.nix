{
  pkgs,
  platform,
  repositoryPath,
  ...
}:
{
  tags = [ "gui" ];

  packages = [
    # nixpkgs can't build the macOS app, so it repackages the official one.
    (if platform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty)
  ];

  home =
    { config, ... }:
    {
      xdg.configFile."ghostty/config".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/features/ghostty/config";
    };
}
