# What every Mac gets.
{ machine, settings, ... }@args:
{
  tags = [ "darwin" ];

  system = [
    ./defaults.nix
    (import ./homebrew.nix args)
    {
      networking.hostName = machine.hostname;
      networking.computerName = machine.hostname;
      system.primaryUser = settings.username;
      time.timeZone = settings.timeZone;
    }
  ];
}
