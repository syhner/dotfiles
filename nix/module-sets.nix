# The sets of modules (see nix/modules.nix) that describe what a host is. Plain
# lists of module names, so configurations combine them with ++.
rec {
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

  # Every host.
  base = cli ++ [
    "btop"
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

  # A host I sit at and work on, rather than a server.
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
  darwin = [
    "darwin-base"
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
  vm-utm = [
    "avahi"
    "nixos-base"
    "share"
    "ssh"
    "systemd-boot"
    "tailscale"
  ];
}
