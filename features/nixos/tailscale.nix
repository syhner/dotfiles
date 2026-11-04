{ lib, tags, ... }:
let
  # Whether other machines on the tailnet can send their internet traffic
  # through this one.
  exitNode = lib.elem "exit-node" tags;
in
{
  services.tailscale = {
    enable = true;

    # An exit node needs IP forwarding.
    useRoutingFeatures = if exitNode then "server" else "none";

    # Applied on every boot with tailscale set. Logging in is done once by
    # hand, with tailscale up, repeating these flags.
    extraSetFlags = [ "--ssh" ] ++ lib.optional exitNode "--advertise-exit-node";
  };
}
