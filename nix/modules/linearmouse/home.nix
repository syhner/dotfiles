{
  config,
  ...
}:
{
  home.file.".config/linearmouse/linearmouse.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/modules/linearmouse/linearmouse.json";
}
