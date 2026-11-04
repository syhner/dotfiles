{
  inputs,
  platform,
  settings,
  ...
}:
{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;
    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = platform.isAarch64;
    # User owning the Homebrew prefix
    user = settings.username;
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
      "stremio"
      "monitorcontrol"
      "helium-browser"
      "lookaway"
      "nvidia-geforce-now"
      "tailscale-app"
      "parsec"
      "raycast"
      "minecraft"
      "elgato-wave-link"
      "openmtp"
    ];
    masApps = {
      "Keynote" = 361285480;
      "TickTick" = 966085870;
    };
  };
}
