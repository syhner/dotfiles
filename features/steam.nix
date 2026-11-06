{ machine, ... }:
{
  tags = [ "gui" ];
  unfree = [
    "steam"
    "steam-unwrapped"
  ];

  system =
    if machine.platform.isDarwin then
      { homebrew.casks = [ "steam" ]; }
    # Steam only runs on x86_64.
    else if machine.platform.isx86_64 then
      { programs.steam.enable = true; }
    else
      { };
}
