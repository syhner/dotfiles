# What every NixOS host gets.
{
  tags = [ "nixos" ];

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
  ];
}
