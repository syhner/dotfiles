{ darwin, pkgs, ... }:
{
  tags = [ "workstation" ];
  unfree = [
    "steam"
    "steam-unwrapped"
  ];

  system =
    if darwin then
      { homebrew.casks = [ "steam" ]; }
    # Steam only runs on x86_64.
    else if pkgs.stdenv.hostPlatform.isx86_64 then
      { programs.steam.enable = true; }
    else
      { };
}
