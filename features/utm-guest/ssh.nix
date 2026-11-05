{
  settings,
  ...
}:
{
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Only allow logging in with a key, and root only with a key. The user's
  # key is the GPG-backed one gpg-agent offers on the Mac. If it's
  # unavailable, the UTM console and Tailscale SSH still work.
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "prohibit-password";
  };
  users.users.${settings.username}.openssh.authorizedKeys.keys = [ settings.sshPublicKey ];

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];
}
