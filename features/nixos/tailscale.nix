{
  ...
}:
{
  services.tailscale = {
    enable = true;
    authKeyFile = "/var/lib/tailscale/auth-key";

    useRoutingFeatures = "server";
    extraUpFlags = [
      "--ssh"
      "--advertise-exit-node"
    ];
  };
}
