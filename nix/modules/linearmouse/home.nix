{
  config,
  repositoryPath,
  ...
}:
{
  home.file.".config/linearmouse/linearmouse.json".source =
    config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/nix/modules/linearmouse/linearmouse.json";

}
