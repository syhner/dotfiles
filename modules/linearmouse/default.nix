{ repositoryPath, ... }:
{
  tags = [ "darwin" ];

  home =
    { config, ... }:
    {
      home.file.".config/linearmouse/linearmouse.json".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/linearmouse/linearmouse.json";
    };

  system.homebrew.casks = [ "linearmouse" ];
}
