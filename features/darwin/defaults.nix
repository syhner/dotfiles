{
  # Enable alternative shell support in nix-darwin.
  # programs.fish.enable = true;

  system.defaults = {
    controlcenter.BatteryShowPercentage = true;

    # Automatically hide and show the menu bar in full screen only
    NSGlobalDomain._HIHideMenuBar = false;
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

    dock.appswitcher-all-displays = true;
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

    # No guest account on the login screen.
    loginwindow.GuestEnabled = false;

    # Download macOS updates, but install them by hand.
    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;

    # Turn off personalised ads and the advertising identifier.
    CustomUserPreferences."com.apple.AdLib" = {
      allowApplePersonalizedAdvertising = false;
      allowIdentifierForAdvertising = false;
      forceLimitAdTracking = true;
    };
  };

  # Requiring the password straight after sleep or the screensaver can't be
  # set here: macOS ignores com.apple.screensaver's askForPassword and
  # askForPasswordDelay. It's set once, by hand, with
  #   sysadminctl -screenLock immediate -password -

  # sudo with Touch ID
  security.pam.services.sudo_local.touchIdAuth = true;
  # and inside tmux, which otherwise runs outside the login session Touch ID needs
  security.pam.services.sudo_local.reattach = true;
}
