# Every module a config can opt into (see nix/module-sets.nix for the sets of
# them that describe what a machine is). A config gets nothing it doesn't ask for.
#
# A module is any of:
#   home      Home Manager module(s)
#   system    NixOS / nix-darwin module(s)
#   packages  pkgs -> list of packages to install
#   fonts     pkgs -> list of fonts to install
#   unfree    names of unfree packages the module installs
#
# Packages and fonts install system-wide, or through Home Manager when it runs
# standalone (see nix/packages.nix), skipping any not available on the platform.
{ lib }:
let
  all = {
    avahi.system = ../modules/nixos/avahi.nix;
    bat.packages = pkgs: [ pkgs.bat ];
    btop.home.programs.btop.enable = true;
    curl.packages = pkgs: [ pkgs.curl ];
    darwin.system = ../modules/darwin/base.nix;
    deskflow = {
      home = ../modules/deskflow/home.nix;
      system = ../modules/deskflow/system.nix;
    };
    direnv.home = ../modules/direnv/home.nix;
    fzf.packages = pkgs: [ pkgs.fzf ];
    gh.packages = pkgs: [ pkgs.gh ];
    ghostty.home = ../modules/ghostty/home.nix;
    git = {
      home = ../modules/git/home.nix;
      packages = pkgs: [
        pkgs.git
        pkgs.git-crypt
      ];
    };
    gpg.home = ../modules/gpg/home.nix;
    graphical.system = ../modules/nixos/graphical.nix;
    grandperspective.packages = pkgs: [ pkgs.grandperspective ];
    homebrew.system = ../modules/homebrew/system.nix;
    kanata = {
      home = ../modules/kanata/home.nix;
      system = ../modules/kanata/system.nix;
      packages = pkgs: [
        (import ../modules/kanata/package.nix pkgs)
        # Installed system-wide, nix-darwin puts the Karabiner manager that
        # system.nix runs in /Applications/Nix Apps.
        pkgs.karabiner-dk
      ];
    };
    linearmouse = {
      home = ../modules/linearmouse/home.nix;
      system = ../modules/linearmouse/system.nix;
    };
    neovim.packages = pkgs: [ pkgs.neovim ];
    nerd-fonts.fonts = pkgs: [ pkgs.nerd-fonts.jetbrains-mono ];
    newsboat = {
      home = ../modules/newsboat/home.nix;
      packages = pkgs: [ pkgs.newsboat ];
    };
    nil.packages = pkgs: [ pkgs.nil ];
    nix.system = ../modules/nix/system.nix;
    # No prebuilt database for x86_64-darwin.
    nix-index-database.system = ../modules/nix-index-database/system.nix;
    nixd.packages = pkgs: [
      # Backport nixd#828: empty hover contents violate the LSP specification.
      (pkgs.nixd.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../modules/nixd/nixd-empty-hover.patch ];
      }))
    ];
    nixos.system = [
      ../modules/nixos/base.nix
      ../modules/nixos/init.nix
    ];
    obsidian = {
      packages = pkgs: [ pkgs.obsidian ];
      unfree = [ "obsidian" ];
    };
    # Unstable nixpkgs no longer supports Intel macOS; use the stable package there.
    opencode.packages = pkgs: [
      (
        if pkgs.stdenv.hostPlatform.system == "x86_64-darwin" then pkgs.opencode else pkgs.unstable.opencode
      )
    ];
    proton-vpn.packages = pkgs: [ pkgs.proton-vpn ];
    qbittorrent.packages = pkgs: [ pkgs.qbittorrent ];
    share.system = ../modules/nixos/share.nix;
    sops = {
      system = ../modules/sops/system.nix;
      packages = pkgs: [ pkgs.sops ];
    };
    spotify = {
      packages = pkgs: [ pkgs.spotify ];
      unfree = [ "spotify" ];
    };
    ssh.system = ../modules/nixos/ssh.nix;
    stow.packages = pkgs: [ pkgs.stow ];
    stylix.system = ../modules/stylix/system.nix;
    systemd-boot.system = ../modules/nixos/systemd-boot.nix;
    tailscale.system = ../modules/nixos/tailscale.nix;
    thunderbird.packages = pkgs: [ pkgs.thunderbird ];
    tmux = {
      home = ../modules/tmux/home.nix;
      packages = pkgs: [ pkgs.tmux ];
    };
    utm.packages = pkgs: [ pkgs.utm ];
    vim.packages = pkgs: [ pkgs.vim ];
    weechat.packages = pkgs: [ pkgs.weechat ];
    wget.packages = pkgs: [ pkgs.wget ];
    yazi.packages = pkgs: [ pkgs.yazi ];
    zed = {
      home = ../modules/zed/home.nix;
      packages = pkgs: [
        pkgs.zed-editor
        pkgs.nixfmt
      ];
    };
    zsh.home = ../modules/zsh/home.nix;
  };

in
{
  select =
    names:
    let
      unknown = builtins.filter (name: !(all ? ${name})) names;

      # Modules load in name order, whatever order a config lists them in.
      selected = builtins.attrValues (lib.getAttrs names all);

      partOf = part: builtins.concatMap (module: lib.toList (module.${part} or [ ])) selected;

      listOf = field: pkgs: builtins.concatMap (module: (module.${field} or (_: [ ])) pkgs) selected;
    in
    if unknown != [ ] then
      throw "unknown modules: ${toString unknown}"
    else
      {
        home = partOf "home";
        system = partOf "system";
        packages = listOf "packages";
        fonts = listOf "fonts";
        unfree = builtins.concatMap (module: module.unfree or [ ]) selected;
      };
}
