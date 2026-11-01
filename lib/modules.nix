{
  lib,
  features,
  extraHomeModules ? [ ],
  extraSystemModules ? [ ],
  hostname ? null,
  homeManagerModule ? null,
}:
let
  inherit (lib) optional optionals;
in
{
  homeModules = [
    ../home.nix
  ]
  ++ extraHomeModules
  ++ optionals features.modules.home (
    optional features.deskflow ../modules/deskflow/home.nix
    ++ optional features.direnv ../modules/direnv/home.nix
    ++ optional features.git ../modules/git/home.nix
    ++ optional features.gpg ../modules/gpg/home.nix
    ++ optional features.ghostty ../modules/ghostty/home.nix
    ++ optional features.kanata ../modules/kanata/home.nix
    ++ optional features.linearmouse ../modules/linearmouse/home.nix
    ++ optional features.newsboat ../modules/newsboat/home.nix
    ++ optional features.packages ../modules/packages/home.nix
    ++ optional features.tmux ../modules/tmux/home.nix
    ++ optional features.zed ../modules/zed/home.nix
    ++ optional features.zsh ../modules/zsh/home.nix
  );
  systemModules =
    extraSystemModules
    ++ optionals features.modules.system (
      optional features.configuration ../hosts/${hostname}/configuration.nix
      ++ optional features.home-manager homeManagerModule
      ++ optional features.darwin.base ../modules/darwin/base.nix
      ++ optional features.deskflow ../modules/deskflow/system.nix
      ++ optional features.homebrew ../modules/homebrew/system.nix
      ++ optional features.kanata ../modules/kanata/system.nix
      ++ optional features.nix ../modules/nix/system.nix
      ++ optional features.nix-index-database ../modules/nix-index-database/system.nix
      ++ optional features.nixos.avahi ../modules/nixos/avahi.nix
      ++ optional features.nixos.base ../modules/nixos/base.nix
      ++ optional features.nixos.graphical ../modules/nixos/graphical.nix
      ++ optional features.nixos.init ../modules/nixos/init.nix
      ++ optional features.nixos.share ../modules/nixos/share.nix
      ++ optional features.nixos.ssh ../modules/nixos/ssh.nix
      ++ optional features.nixos.systemd-boot ../modules/nixos/systemd-boot.nix
      ++ optional features.nixos.tailscale ../modules/nixos/tailscale.nix
      ++ optional features.packages ../modules/packages/system.nix
      ++ optional features.sops ../modules/sops/system.nix
      ++ optional features.stylix ../modules/stylix/system.nix
    );
}
