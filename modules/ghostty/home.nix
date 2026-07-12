{
  config,
  repositoryPath,
  ...
}:
{
  home.file.".config/ghostty/config".source =
    config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/ghostty/config";
}
