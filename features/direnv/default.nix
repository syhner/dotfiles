{ repositoryPath, ... }:
{
  tags = [ "base" ];

  home =
    { config, ... }:
    {
      programs.direnv.enable = true;
      programs.direnv.nix-direnv.enable = true;

      xdg.configFile."direnv/direnv.toml".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/features/direnv/direnv.toml";
    };
}
