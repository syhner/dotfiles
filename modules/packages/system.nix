{
  inputs,
  pkgs,
  lib,
  platform,
  ...
}:
let
  unfreeNames = [
    "obsidian"
    "spotify"
  ];

  unfreePkgs = map (name: lib.getAttr name pkgs) unfreeNames;
in
if (platform == "nixos" || platform == "darwin") then
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
      pkgs.stow
      pkgs.fzf
      pkgs.neovim
      pkgs.tmux
      pkgs.nil
      pkgs.nixd
      pkgs.proton-vpn
      pkgs.unstable.opencode
    ]
    ++ unfreePkgs;

    fonts.packages = [
      pkgs.nerd-fonts.jetbrains-mono
    ];
  }
else
  { }
