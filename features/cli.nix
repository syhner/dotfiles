# Command-line tools with no configuration of their own.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.cli.enable {
    packages = [
      pkgs.bat
      pkgs.curl
      pkgs.fzf
      pkgs.gh
      pkgs.neovim
      pkgs.ripgrep
      pkgs.tree
      pkgs.vim
      pkgs.weechat
      pkgs.wget
      pkgs.yazi
    ];
  };
}
