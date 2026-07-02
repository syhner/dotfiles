{
  inputs,
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

  nixpkgs.overlays = [
    (final: prev: {
      # namespace unstable packages under pkgs.unstable
      unstable = import inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
      };
      # allow kanata to run shell commands
      kanata = prev.kanata.override {
        withCmd = true;
      };
    })
  ];
  environment.systemPackages = [
    pkgs.bat
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
    pkgs.unstable.opencode
    pkgs.utm
    pkgs.btop
  ]
  ++ unfreePkgs;

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
  ];
}
