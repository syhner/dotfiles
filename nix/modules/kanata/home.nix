{
  config,
  repositoryPath,
  ...
}:
{
  home.file.".config/kanata/kanata.kbd".source =
    config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/nix/modules/kanata/kanata.kbd";
}
