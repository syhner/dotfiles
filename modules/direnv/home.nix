{
  config,
  repositoryPath,
  ...
}:
{
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  home.file.".config/direnv/direnv.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/direnv/direnv.toml";
}
