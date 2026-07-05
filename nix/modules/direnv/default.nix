{
  config,
  ...
}:
{
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  # maybe want to manage this with stow to avoid having to use absolute paths?
  home.file.".config/direnv/direnv.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/modules/direnv/direnv.toml";
}
