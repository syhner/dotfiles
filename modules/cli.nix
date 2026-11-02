# Command-line tools with no configuration of their own.
{
  tags = [ "base" ];

  packages = pkgs: [
    pkgs.bat
    pkgs.curl
    pkgs.fzf
    pkgs.gh
    pkgs.neovim
    pkgs.stow
    pkgs.vim
    pkgs.weechat
    pkgs.wget
    pkgs.yazi
  ];
}
