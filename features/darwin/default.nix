# What every Mac gets.
{
  config,
  lib,
  machine,
  settings,
  ...
}@args:
{
  config = lib.mkIf config.features.darwin.enable {
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
  };
}
