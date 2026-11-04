# What every Mac gets.
{ settings, ... }@args:
{
  tags = [ "darwin" ];

  system = [
    ./defaults.nix
    (import ./homebrew.nix args)
    { time.timeZone = settings.timeZone; }
  ];
}
