# What every NixOS host gets.
{
  hostname,
  settings,
  ...
}:
{
  tags = [ "nixos" ];

  system = [
    {
      networking.hostName = hostname;

      # Configure network connections interactively with nmcli or nmtui.
      networking.networkmanager.enable = true;

      time.timeZone = settings.timeZone;

      # Configure network proxy if necessary
      # networking.proxy.default = "http://user:password@proxy:port/";
      # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

      i18n.defaultLocale = "en_US.UTF-8";
      console = {
        # font = "Lat2-Terminus16";
        keyMap = "us";
        # useXkbConfig = true; # use xkb.options in tty.
      };

      # Enable the X11 windowing system.
      # services.xserver.enable = true;

      # Configure keymap in X11
      # services.xserver.xkb.layout = "us";
      # services.xserver.xkb.options = "eurosign:e,caps:escape";

      # Enable CUPS to print documents.
      # services.printing.enable = true;

      # Enable sound.
      # services.pulseaudio.enable = true;
      # OR
      # services.pipewire = {
      #   enable = true;
      #   pulse.enable = true;
      # };

      # Enable touchpad support (enabled default in most desktopManager).
      # services.libinput.enable = true;

      # Define a user account. Don't forget to set a password with ‘passwd’.
      users.users.${settings.username} = {
        isNormalUser = true;
        extraGroups = [
          "wheel" # Enable 'sudo' for the user.
          "networkmanager" # Lets the user manage network connections without root.
        ];
        # Temporary password, change after first login
        initialPassword = "changeme";
      };

      # programs.firefox.enable = true;

      # Some programs need SUID wrappers, can be configured further or are
      # started in user sessions.
      # programs.mtr.enable = true;
      # programs.gnupg.agent = {
      #   enable = true;
      #   enableSSHSupport = true;
      # };

      # Copy the NixOS configuration file and link it from the resulting system
      # (/run/current-system/configuration.nix). This is useful in case you
      # accidentally delete configuration.nix.
      # system.copySystemConfiguration = true;

      # -----------------------------------

      # Enable sudo for users in wheel.
      # This is the standard way to administer a NixOS machine as a normal user.
      security.sudo.enable = true;

      # -----------------------------------

      users.users.root.openssh.authorizedKeys.keys = [ settings.sshPublicKey ];

      # This option defines the first version of NixOS you have installed on this particular machine,
      # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
      #
      # Most users should NEVER change this value after the initial install, for any reason,
      # even if you've upgraded your system to a new NixOS release.
      #
      # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
      # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
      # to actually do that.
      #
      # This value being lower than the current NixOS release does NOT mean your system is
      # out of date, out of support, or vulnerable.
      #
      # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
      # and migrated your data accordingly.
      #
      # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
      system.stateVersion = "26.05"; # Did you read the comment?
    }
  ];
}
