# What every NixOS host gets, and what a host can ask for on top.
{
  avahi ? false,
  graphical ? false,
  share ? false,
  ssh ? false,
  systemd-boot ? false,
}:
let
  optional = enable: file: if enable then [ file ] else [ ];
in
{
  tags = [ ];

  # You can use https://search.nixos.org/ to find more packages (and options).
  packages = pkgs: [
    pkgs.vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    pkgs.wget
    pkgs.curl
    pkgs.git
  ];

  system = [
    ./base.nix
    ./init.nix
    ./tailscale.nix
  ]
  # Local network hostname discovery.
  ++ optional avahi ./avahi.nix
  # A GNOME desktop.
  ++ optional graphical ./graphical.nix
  # The folder UTM shares with the VM.
  ++ optional share ./share.nix
  # OpenSSH, with its port open.
  ++ optional ssh ./ssh.nix
  # The systemd-boot EFI boot loader.
  ++ optional systemd-boot ./systemd-boot.nix;
}
