# Every module a configuration can opt into, and under sets the sets of them
# that describe what a host is. A configuration lists the modules it wants and
# gets nothing it doesn't ask for.
#
# A module has any of these parts:
#   home        Home Manager module(s)
#   system      NixOS / nix-darwin module(s)
#   standalone  Home Manager module(s) doing the system part's job when Home
#               Manager runs standalone
#   packages    function from pkgs to the packages to install
#   fonts       function from pkgs to the fonts to install
#   unfree      names of unfree packages the module installs, from stable or
#               unstable
#
# Packages and fonts install system-wide, or through Home Manager when it runs
# standalone (see nix/packages.nix), skipping any not available on the platform.
# Unfree names can't use pkgs: they configure it (see nix/pkgs.nix).
rec {
  avahi.system = ../modules/avahi/system.nix;
  bat.packages = pkgs: [ pkgs.bat ];
  btop.home.programs.btop.enable = true;
  curl.packages = pkgs: [ pkgs.curl ];
  darwin-base.system = ../modules/darwin-base/system.nix;
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
  graphical.system = ../modules/graphical/system.nix;
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
  nix-index-database = {
    system = ../modules/nix-index-database/system.nix;
    standalone = ../modules/nix-index-database/home.nix;
  };
  nixd.packages = pkgs: [
    # Backport nixd#828: empty hover contents violate the LSP specification.
    (pkgs.nixd.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ../modules/nixd/nixd-empty-hover.patch ];
    }))
  ];
  nixos-base.system = [
    ../modules/nixos-base/system.nix
    ../modules/nixos-base/init.nix
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
  share.system = ../modules/share/system.nix;
  sops = {
    system = ../modules/sops/system.nix;
    standalone = ../modules/sops/home.nix;
    packages = pkgs: [ pkgs.sops ];
  };
  spotify = {
    packages = pkgs: [ pkgs.spotify ];
    unfree = [ "spotify" ];
  };
  ssh.system = ../modules/ssh/system.nix;
  stow.packages = pkgs: [ pkgs.stow ];
  stylix.system = ../modules/stylix/system.nix;
  systemd-boot.system = ../modules/systemd-boot/system.nix;
  tailscale.system = ../modules/tailscale/system.nix;
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

  sets = {
    # Command-line tools with no configuration of their own.
    cli = [
      bat
      curl
      fzf
      gh
      neovim
      stow
      vim
      weechat
      wget
      yazi
    ];

    # Every host.
    base = sets.cli ++ [
      btop
      direnv
      git
      gpg
      newsboat
      nix
      sops
      stylix
      tmux
      zsh
    ];

    # A host I sit at and work on, rather than a server.
    workstation = [
      ghostty
      nerd-fonts
      nil
      nix-index-database
      nixd
      obsidian
      opencode
      proton-vpn
      spotify
      thunderbird
    ];

    # A Mac.
    darwin = [
      darwin-base
      deskflow
      grandperspective
      homebrew
      kanata
      linearmouse
      qbittorrent
      utm
      zed
    ];

    # A NixOS VM running in UTM on the Mac.
    vm-utm = [
      avahi
      nixos-base
      share
      ssh
      systemd-boot
      tailscale
    ];
  };
}
