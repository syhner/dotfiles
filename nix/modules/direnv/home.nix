{
  config,
  ...
}:
{
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  home.file.".config/direnv/direnv.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/modules/direnv/direnv.toml";
}
