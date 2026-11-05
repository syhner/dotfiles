# Tailscale, on every system. On NixOS, every machine also serves Tailscale
# SSH, and one tagged exit-node lets others send their internet traffic
# through it. A Mac usually has the app, but one the others build on (see
# features/remote-builds.nix) runs the open source tailscaled instead: on
# macOS only it can serve Tailscale SSH. Logging in is done once by hand, with
# sudo tailscale up --ssh --advertise-tags=tag:fleet (see nix-remote.nix), plus
# --advertise-exit-node on an exit node.
{
  builder,
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
    else if builder == null then
      { homebrew.casks = [ "tailscale-app" ]; }
    else
      { services.tailscale.enable = true; };
}
