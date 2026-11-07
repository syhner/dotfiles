{
  lib,
  pkgs,
  symlinkToCheckout,
  ...
}:
let
  # In the order tmux loads them.
  plugins = [
    pkgs.tmuxPlugins.vim-tmux-navigator
    pkgs.tmuxPlugins.sensible
    pkgs.tmuxPlugins.yank
    pkgs.tmuxPlugins.resurrect
    pkgs.tmuxPlugins.continuum
  ];
in
{
  tags = [ "base" ];
  packages = [ pkgs.tmux ];

  home = {
    xdg.configFile."tmux/tmux.conf".source = symlinkToCheckout ./tmux.conf;

    # Sourced at the end of tmux.conf.
    xdg.configFile."tmux/plugins.conf".text = lib.concatMapStrings (
      plugin: "run-shell ${plugin.rtp}\n"
    ) plugins;
  };
}
