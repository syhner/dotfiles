{
  pkgs,
  username,
  hostname,
  kernel,
  ...
}:
if (kernel == "linux") then
  {
    networking.hostName = hostname;

    time.timeZone = "Europe/Paris";

    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      # font = "Lat2-Terminus16";
      keyMap = "us";
      # useXkbConfig = true; # use xkb.options in tty.
    };

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.${username} = {
      isNormalUser = true;
      extraGroups = [
        "wheel" # Enable 'sudo' for the user.
        "networkmanager" # Lets the user manage network connections without root.
      ];
      # Temporary password, change after first login
      initialPassword = "changeme";
      packages = with pkgs; [
        vim
      ];
    };

    # Enable the OpenSSH daemon.
    services.openssh.enable = true;

    # Open ports in the firewall.
    networking.firewall.allowedTCPPorts = [ 22 ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;

    # -----------------------------------

    # Enable sudo for users in wheel.
    # This is the standard way to administer a NixOS machine as a normal user.
    security.sudo.enable = true;

    # Avahi for .local hostname discovery
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        workstation = true;
      };
    };

    fileSystems."/mnt/share" = {
      device = "share"; # share name
      fsType = "9p"; # filesystem protocol, 9p is usual for QEMU
      options = [
        "trans=virtio" # usual for QEMU
        "version=9p2000.L" # protocol variant with Linux extensions, commonly required for Linux guests
        "rw" # read and write access
      ];
    };

    # -----------------------------------

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable touchpad support (enabled default in most desktopManager).
    # services.libinput.enable = true;

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
  }
else
  { }
