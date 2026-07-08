{
  platform,
  ...
}:
if (platform == "nixos" || platform == "darwin") then
  {
    # Enable modern nix command UX + flakes
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  }
else
  { }
