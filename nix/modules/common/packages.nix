{
  pkgs,
  lib,
  ...
}:
let
  unfreeNames = [
    "obsidian"
    "spotify"
  ];

  unfreePkgs = map (name: lib.getAttr name pkgs) unfreeNames;
in
{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfreeNames;

  environment.systemPackages = [
    pkgs.vim
    pkgs.wget
    pkgs.curl
    pkgs.git
    pkgs.stow
    pkgs.fzf
    pkgs.neovim
    pkgs.tmux
    pkgs.nil
    pkgs.nixd
    pkgs.zed-editor
    # Karabiner-VirtualHIDDevice driver for kanata
    pkgs.karabiner-dk
    pkgs.kanata
    pkgs.proton-vpn
    pkgs.opencode
    pkgs.utm
  ]
  ++ unfreePkgs;

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
  ];
}
