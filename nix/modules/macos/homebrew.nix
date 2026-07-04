{
  username,
  ...
}:
{
  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;
    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = true;
    # User owning the Homebrew prefix
    user = username;
    # Automatically migrate existing Homebrew installations
    autoMigrate = true;
  };

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
      "nvidia-geforce-now"
      "linearmouse"
    ];
    masApps = {
      "Keynote" = 361285480;
    };
  };
}
