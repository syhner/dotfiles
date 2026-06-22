{
  ...
}:
{
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # Enable alternative shell support in nix-darwin.
  # programs.fish.enable = true;

  system.defaults = {
    controlcenter.BatteryShowPercentage = true;

    # Press and hold key for accents behaviour
    NSGlobalDomain.ApplePressAndHoldEnabled = false;
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

    # Scroll with ctrl
    universalaccess.closeViewScrollWheelToggle = true;
  };

  # sudo with Touch ID
  security.pam.services.sudo_local.touchIdAuth = true;

  # system.keyboard = {
  #   enableKeyMapping = true;
  #   remapCapsLockToEscape = true;
  # };

  system.activationScripts.extraActivation.text = ''
    if ! pkgutil --pkg-info=com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
      softwareupdate --install-rosetta --agree-to-license
    fi
  '';
}
