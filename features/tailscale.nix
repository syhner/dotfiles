# Tailscale, on every system. Every NixOS machine serves Tailscale SSH, and
# one tagged exit-node lets others send their internet traffic through it. A
# Mac usually has the app, but one the others build on or download from (see
# features/fleet-builders and features/fleet-substituters.nix) runs the open
# source tailscaled instead, and serves Tailscale SSH too: on macOS only it
# can, and it gives the cache a tailscale command to publish with. Logging in
# is done once by hand (see the README), with
# sudo tailscale up --advertise-tags=tag:fleet (see fleet-access), plus
# --advertise-exit-node on an exit node.
{ lib, machine, ... }:
let
  exitNode = lib.elem "exit-node" machine.tags;
in
{
  tags = [
    "nixos"
    "darwin"
  ];

  system =
    if machine.platform.isLinux then
      {
        services.tailscale = {
          enable = true;

          # An exit node needs IP forwarding.
          useRoutingFeatures = if exitNode then "server" else "none";

          # Applied on every boot with tailscale set.
          extraSetFlags = [ "--ssh" ] ++ lib.optional exitNode "--advertise-exit-node";
        };
      }
    else if !machine.servesFleet then
      { homebrew.casks = [ "tailscale-app" ]; }
    else
      (
        { config, ... }:
        {
          services.tailscale.enable = true;

          # tailscaled writes /etc/resolver/ts.net itself, and won't write
          # through nix-darwin's link there, which stops its DNS setup.
          environment.etc."resolver/ts.net".enable = lib.mkForce false;

          # Serves Tailscale SSH, set on boot, as NixOS does with
          # extraSetFlags. tailscale set works before logging in too; run
          # before tailscaled is up, it fails and launchd runs it again.
          launchd.daemons.tailscale-set.serviceConfig = {
            ProgramArguments = [
              "${config.services.tailscale.package}/bin/tailscale"
              "set"
              "--ssh"
            ];
            RunAtLoad = true;
            KeepAlive.SuccessfulExit = false;
            StandardErrorPath = "/var/log/tailscale-set.log";
          };
        }
      );
}
