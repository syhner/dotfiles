{
  settings,
  hostname,
  ...
}:
{
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  networking.hostName = hostname;
  networking.computerName = hostname;
  system.primaryUser = settings.username;
}
