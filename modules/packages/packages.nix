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
  unfreePkgs =
    [ ]
    ++ lib.optionals cfg.package.obsidian [ pkgs.obsidian ]
    ++ lib.optionals cfg.package.spotify [ pkgs.spotify ];

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
      pkgs.git
      pkgs.stow
      pkgs.fzf
      pkgs.neovim
      pkgs.tmux
    ]
    ++ lib.optional cfg.package.nil pkgs.nil
    ++ lib.optional cfg.package.nixd pkgs.nixd
    ++ lib.optional cfg.package.proton-vpn pkgs.proton-vpn
    ++ lib.optional cfg.package.opencode pkgs.unstable.opencode
    ++ lib.optional cfg.darwin.base pkgs.utm
    ++ lib.optional cfg.darwin.base pkgs.grandperspective
    ++ lib.optional cfg.kanata pkgs.kanata
    ++ lib.optional cfg.kanata pkgs.karabiner-dk
    ++ lib.optional cfg.sops pkgs.sops
    ++ lib.optional cfg.zed pkgs.zed-editor
    ++ unfreePkgs
  );

  fonts = pkgAvailableOnHostPlatform (
    lib.optional cfg.package.nerd-fonts pkgs.nerd-fonts.jetbrains-mono
  );
}
