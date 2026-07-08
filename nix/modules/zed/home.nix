{
  config,
  ...
}:
{
  home.file.".config/zed/keymap.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/modules/zed/keymap.json";

  home.file.".config/zed/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/modules/zed/settings.json";

  home.file."Library/Application Support/Zed/Extensions/index.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/modules/zed/extensions.json";
}
