{
  platform,
  pkgs,
  ...
}:
if (platform == "darwin") then
  {
    environment.systemPackages = [
      pkgs.utm
      pkgs.grandperspective
    ];

    # Enable alternative shell support in nix-darwin.
    # programs.fish.enable = true;

    system.defaults = {
      controlcenter.BatteryShowPercentage = true;

      # Press and hold key for accents behaviour
      NSGlobalDomain.ApplePressAndHoldEnabled = false;
      NSGlobalDomain.AppleShowAllExtensions = true;
      NSGlobalDomain.AppleShowAllFiles = true;
      # 120, 94, 68, 35, 25, 15
      NSGlobalDomain.InitialKeyRepeat = 15;
      # 120, 90, 60, 30, 12, 6, 2
      NSGlobalDomain.KeyRepeat = 2;
      NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
      NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;

      dock.autohide = true;
      dock.autohide-delay = 0.0;
      # Remove Dock auto-hide animation time
      dock.autohide-time-modifier = 0.0;
      # Show only open apps in Dock (no persistent/static apps)
      dock.static-only = true;

      finder.NewWindowTarget = "Desktop";
      finder.ShowPathbar = true;
      finder._FXSortFoldersFirst = true;
      # Allow quitting Finder with Cmd+Q
      finder.QuitMenuItem = true;
      # Prefer column view
      finder.FXPreferredViewStyle = "clmv";

      screencapture.target = "clipboard";
    };

    # doesn't work
    # system.defaults.CustomSystemPreferences.NSGlobalDomain."com.apple.screensaver".askForPassword = 1;
    # system.defaults.CustomSystemPreferences.NSGlobalDomain."com.apple.screensaver".askForPasswordDelay =
    #   0;

    # sudo with Touch ID
    security.pam.services.sudo_local.touchIdAuth = true;
  }
else
  { }
