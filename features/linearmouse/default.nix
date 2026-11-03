{ repositoryPath, ... }:
{
  tags = [ "darwin" ];

  home =
    { config, ... }:
    {
      xdg.configFile."linearmouse/linearmouse.json".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/features/linearmouse/linearmouse.json";
    };

  system.homebrew.casks = [ "linearmouse" ];
}
