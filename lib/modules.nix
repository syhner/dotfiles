# Every module a config can opt into, and the sets of them that describe what a
# machine is. A config gets nothing it doesn't ask for.
#
# A module is any of:
#   home      Home Manager module(s)
#   system    NixOS / nix-darwin module(s)
#   packages  pkgs -> list of packages to install
#   fonts     pkgs -> list of fonts to install
#   unfree    names of unfree packages the module installs
#
# A module with its own directory describes itself in its default.nix.
#
# Packages and fonts install system-wide, or through Home Manager when it runs
# standalone (see lib/packages.nix), skipping any not available on the platform.
let
  all = {
    avahi.system = ../modules/nixos/avahi.nix;
    bat.packages = pkgs: [ pkgs.bat ];
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
    kanata = import ../modules/kanata;
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

  # Plain lists of module names, so configs combine them with ++.
  sets = rec {
    # Command-line tools with no configuration of their own.
    cli = [
      "bat"
      "curl"
      "fzf"
      "gh"
      "neovim"
      "stow"
      "vim"
      "weechat"
      "wget"
      "yazi"
    ];

    # Every machine.
    base = cli ++ [
      "direnv"
      "git"
      "gpg"
      "newsboat"
      "nix"
      "sops"
      "stylix"
      "tmux"
      "zsh"
    ];

    # A machine I sit at and work on, rather than a server.
    workstation = [
      "ghostty"
      "nerd-fonts"
      "nil"
      "nix-index-database"
      "nixd"
      "obsidian"
      "opencode"
      "proton-vpn"
      "spotify"
      "thunderbird"
    ];

    # A Mac.
    mac = [
      "darwin"
      "deskflow"
      "grandperspective"
      "homebrew"
      "kanata"
      "linearmouse"
      "qbittorrent"
      "utm"
      "zed"
    ];

    # A NixOS VM running in UTM on the Mac.
    utm-vm = [
      "avahi"
      "nixos"
      "share"
      "ssh"
      "systemd-boot"
      "tailscale"
    ];
  };

in
{
  inherit sets;

  select =
    names:
    let
      unknown = builtins.filter (name: !(all ? ${name})) names;

      # Modules load in the order above, whatever order a config lists them in.
      selected = map (name: all.${name}) (
        builtins.filter (name: builtins.elem name names) (builtins.attrNames all)
      );

      partOf =
        part:
        builtins.concatMap (
          module:
          let
            files = module.${part} or [ ];
          in
          if builtins.isList files then files else [ files ]
        ) selected;

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
