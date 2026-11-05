# Tailscale, on every system. On NixOS, every machine also serves Tailscale
# SSH, and one tagged exit-node lets others send their internet traffic
# through it. A Mac has the app. Logging in is done once by hand, with
# sudo tailscale up --ssh, plus --advertise-exit-node on an exit node.
{
  lib,
  platform,
  tags,
  ...
}:
let
  exitNode = lib.elem "exit-node" tags;
in
{
  tags = [
    "nixos"
    "darwin"
  ];

  system =
    if platform.isLinux then
      {
        services.tailscale = {
          enable = true;

          # An exit node needs IP forwarding.
          useRoutingFeatures = if exitNode then "server" else "none";

          # Applied on every boot with tailscale set.
          extraSetFlags = [ "--ssh" ] ++ lib.optional exitNode "--advertise-exit-node";
        };
      }
    else
      { homebrew.casks = [ "tailscale-app" ]; };
}
