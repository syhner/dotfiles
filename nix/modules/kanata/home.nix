{
  config,
  ...
}:
{
  home.file.".config/kanata/kanata.kbd".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/modules/kanata/kanata.kbd";
}
