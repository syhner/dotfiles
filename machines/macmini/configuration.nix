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

  # It's there to be built on, so it never sleeps, and comes back on after a
  # power cut.
  power.sleep.computer = "never";
  power.restartAfterPowerFailure = true;
}
