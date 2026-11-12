{
  config,
  lib,
  machine,
  ...
}:
{
  config = lib.mkIf config.features.steam.enable {
    # Homebrew, for the cask.
    features.darwin.enable = lib.mkIf machine.platform.isDarwin true;

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
  };
}
