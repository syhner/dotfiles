{
  ...
}:
{
  services.tailscale = {
    enable = true;
    extraSetFlags = [
      "--ssh"
    ];
    authKeyFile = "/var/lib/tailscale/auth-key";
  };
}
