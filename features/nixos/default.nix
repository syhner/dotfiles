# What every NixOS system gets.
{
  lib,
  machine,
  settings,
  ...
}:
let
  # In WSL, Windows manages the network (see features/wsl.nix).
  networkmanager = !lib.elem "wsl" machine.tags;
in
{
  tags = [ "nixos" ];

  system = [
    {
      networking.hostName = machine.hostname;

      # Configure network connections interactively with nmcli or nmtui.
      networking.networkmanager.enable = networkmanager;

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
        extraGroups = [
          "wheel" # Enable 'sudo' for the user.
        ]
        # Lets the user manage network connections without root.
        ++ lib.optional networkmanager "networkmanager";
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
    }
  ];
}
