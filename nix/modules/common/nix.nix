{
  pkgs,
  ...
}:
{
  # Enable modern nix command UX + flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
