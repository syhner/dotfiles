{
  ...
}:
{
  homebrew = {
    enable = true;
    brews = [
      "mas"
      "mole"
    ];
    casks = [
      "obs"
      "vlc"
      "ghostty"
      "stremio"
      "monitorcontrol"
      "helium-browser"
      "steam"
      # when installed through nixpkgs, gets stuck on installing helper too
      "discord"
      "lookaway"
    ];
    masApps = {
      "Keynote" = 361285480;
    };
  };
}
