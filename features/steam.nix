{ platform, ... }:
{
  tags = [ "gui" ];
  unfree = [
    "steam"
    "steam-unwrapped"
  ];

  system =
    if platform.isDarwin then
      { homebrew.casks = [ "steam" ]; }
    # Steam only runs on x86_64.
    else if platform.isx86_64 then
      { programs.steam.enable = true; }
    else
      { };
}
