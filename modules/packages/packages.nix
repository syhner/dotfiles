{
  inputs,
  pkgs,
  lib,
  cfg,
  ...
}:
let
  unfreeNames = [
    "obsidian"
    "spotify"
  ];
  unfreePkgs = map (name: lib.getAttr name pkgs) unfreeNames;

  pkgAvailableOnHostPlatform = lib.filter (pkg: lib.meta.availableOn pkgs.stdenv.hostPlatform pkg);
in
{
  nixpkgsConfig = {
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfreeNames;
  };

  overlays = [
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

  packages = pkgAvailableOnHostPlatform (
    [
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
    ++ unfreePkgs
    ++ lib.optional (cfg.darwin.base) pkgs.utm
    ++ lib.optional (cfg.darwin.base) pkgs.grandperspective
    ++ lib.optional (cfg.git) pkgs.git
    ++ lib.optional (cfg.kanata) pkgs.kanata
    ++ lib.optional (cfg.kanata) pkgs.karabiner-dk
    ++ lib.optional (cfg.zed) pkgs.zed-editor
  );

  fonts = pkgAvailableOnHostPlatform [ pkgs.nerd-fonts.jetbrains-mono ];
}
