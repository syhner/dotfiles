{
  inputs,
  pkgs,
  lib,
  features,
  ...
}:
let
  unfreeNames = [
    "obsidian"
    "spotify"
  ];
  unfreePkgs =
    [ ]
    ++ lib.optionals features.package.obsidian [ pkgs.obsidian ]
    ++ lib.optionals features.package.spotify [ pkgs.spotify ];

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
      # Backport nixd#828: empty hover contents violate the LSP specification.
      nixd = prev.nixd.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./nixd-empty-hover.patch ];
      });
    })
  ];

  packages = pkgAvailableOnHostPlatform (
    [
      pkgs.bat
      pkgs.vim
      pkgs.wget
      pkgs.curl
      pkgs.git
      pkgs.git-crypt
      pkgs.stow
      pkgs.tmux
      pkgs.fzf
      pkgs.yazi
      pkgs.neovim
      pkgs.gnupg
      pkgs.weechat
      pkgs.newsboat
      pkgs.gh
    ]
    ++ lib.optional features.package.nil pkgs.nil
    ++ lib.optional features.package.nixd pkgs.nixd
    ++ lib.optional features.package.proton-vpn pkgs.proton-vpn
    # Unstable nixpkgs no longer supports Intel macOS; use the stable package there.
    ++ lib.optional features.package.opencode (
      if pkgs.stdenv.hostPlatform.system == "x86_64-darwin" then pkgs.opencode else pkgs.unstable.opencode
    )
    ++ lib.optional features.darwin.base pkgs.utm
    ++ lib.optional features.darwin.base pkgs.grandperspective
    ++ lib.optional features.kanata pkgs.kanata
    ++ lib.optional features.kanata pkgs.karabiner-dk
    ++ lib.optional features.qbittorrent pkgs.qbittorrent
    ++ lib.optional features.sops pkgs.sops
    ++ lib.optional features.thunderbird pkgs.thunderbird
    ++ lib.optional features.zed pkgs.zed-editor
    ++ lib.optional features.zed pkgs.nixfmt
    ++ unfreePkgs
  );

  fonts = pkgAvailableOnHostPlatform (
    lib.optional features.package.nerd-fonts pkgs.nerd-fonts.jetbrains-mono
  );
}
