{ ... }:
{
  tags = [ "base" ];

  # Enable modern nix command UX + flakes
  system.nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
