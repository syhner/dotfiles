{
  tags = [ "workstation" ];
  unfree = [
    "steam"
    "steam-unwrapped"
  ];

  system =
    {
      lib,
      pkgs,
      systemKey,
      ...
    }:
    if systemKey == "darwin" then
      { homebrew.casks = [ "steam" ]; }
    else
      # Steam only runs on x86_64. lib.mkIf rather than if, because the
      # module's attributes can't depend on pkgs.
      lib.mkIf pkgs.stdenv.hostPlatform.isx86_64 { programs.steam.enable = true; };
}
