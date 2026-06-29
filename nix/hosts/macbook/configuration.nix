{
  username,
  hostnames,
  ...
}:
{
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  nixpkgs.hostPlatform = "aarch64-darwin";
  networking.hostName = hostnames.darwin;
  networking.computerName = hostnames.darwin;
  system.primaryUser = username;
}
