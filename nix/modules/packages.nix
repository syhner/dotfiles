{
  pkgs,
  ...
}:
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.git
    pkgs.stow
    pkgs.neovim
    pkgs.tmux
    pkgs.obsidian
    pkgs.nil
    pkgs.nixd
    pkgs.zed-editor
    pkgs.spotify
    # Karabiner-VirtualHIDDevice driver for kanata
    pkgs.karabiner-dk
    pkgs.kanata
    pkgs.proton-vpn
  ];

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
  ];
}
