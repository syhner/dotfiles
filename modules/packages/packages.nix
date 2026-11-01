{
  inputs,
  pkgs,
  lib,
  enabled,
  ...
}:
let
  unfreeNames = [
    "obsidian"
    "spotify"
  ];
  unfreePkgs =
    [ ]
    ++ lib.optionals enabled.obsidian [ pkgs.obsidian ]
    ++ lib.optionals enabled.spotify [ pkgs.spotify ];

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
    ++ lib.optional enabled.nil pkgs.nil
    ++ lib.optional enabled.nixd pkgs.nixd
    ++ lib.optional enabled.proton-vpn pkgs.proton-vpn
    # Unstable nixpkgs no longer supports Intel macOS; use the stable package there.
    ++ lib.optional enabled.opencode (
      if pkgs.stdenv.hostPlatform.system == "x86_64-darwin" then pkgs.opencode else pkgs.unstable.opencode
    )
    ++ lib.optional enabled.utm pkgs.utm
    ++ lib.optional enabled.grandperspective pkgs.grandperspective
    ++ lib.optional enabled.kanata pkgs.kanata
    ++ lib.optional enabled.kanata pkgs.karabiner-dk
    ++ lib.optional enabled.qbittorrent pkgs.qbittorrent
    ++ lib.optional enabled.sops pkgs.sops
    ++ lib.optional enabled.thunderbird pkgs.thunderbird
    ++ lib.optional enabled.zed pkgs.zed-editor
    ++ lib.optional enabled.zed pkgs.nixfmt
    ++ unfreePkgs
  );

  fonts = pkgAvailableOnHostPlatform (lib.optional enabled.nerd-fonts pkgs.nerd-fonts.jetbrains-mono);
}
