{
  username,
  hostname,
  ...
}:
{
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  nixpkgs.hostPlatform = "aarch64-darwin";
  networking.hostName = hostname;
  networking.computerName = hostname;
  system.primaryUser = username;

  users.users.${username} = {
    # required for home-manager
    home = "/Users/${username}";
  };
}
