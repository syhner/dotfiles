{
  config,
  repositoryPath,
  ...
}:
{
  home.file.".newsboat/config".source =
    config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/newsboat/config";
}
