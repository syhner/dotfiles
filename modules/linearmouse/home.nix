{
  config,
  repositoryPath,
  ...
}:
{
  home.file.".config/linearmouse/linearmouse.json".source =
    config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/linearmouse/linearmouse.json";

}
