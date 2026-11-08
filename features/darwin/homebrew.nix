{
  inputs,
  machine,
  settings,
  ...
}:
{ config, ... }:
{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;
    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = machine.platform.isAarch64;
    # User owning the Homebrew prefix
    user = settings.username;
    # Automatically migrate existing Homebrew installations
    autoMigrate = true;

    # The taps are flake inputs, so what's installed only changes when
    # flake.lock does. brew can't tap, untap or update them itself: a
    # feature with a cask from another tap adds that tap here too. With
    # homebrew-core here, brew installs from it rather than from Homebrew's
    # API, which always has the newest.
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = false;
  };

  homebrew = {
    enable = true;
    # The taps above, so brew bundle doesn't try to tap anything else.
    taps = builtins.attrNames config.nix-homebrew.taps;
    brews = [
      "mas"
      "mole"
    ];
    casks = [
      "chatgpt"
      "stremio"
      "monitorcontrol"
      "helium-browser"
      "lookaway"
      "nvidia-geforce-now"
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
