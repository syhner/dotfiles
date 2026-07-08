{
  config,
  repositoryPath,
  ...
}:
{
  home.file.".config/kanata/kanata.kbd".source =
    config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/kanata/kanata.kbd";
}
