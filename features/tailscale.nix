# Tailscale, on every system. Every NixOS machine serves Tailscale SSH, and
# one with features.tailscale.exitNode lets others send their internet
# traffic through it. A Mac usually has the app, but one the others build on
# or download from (see features/fleet-builders and
# features/fleet-substituters.nix) runs the open source tailscaled instead,
# and serves Tailscale SSH too: on macOS only it can, and it gives the cache
# a tailscale command to publish with. A machine with secrets logs itself in,
# tagged tag:fleet (see fleet-access), with the OAuth client secret in
# secrets/fleet.yaml; any other is logged in once by hand (see the README).
{
  config,
  lib,
  machine,
  pkgs,
  ...
}:
let
  inherit (config.features.tailscale) exitNode;
  hasSecrets = config.features.secrets.active;

  # for an OAuth client secret: a lasting node, approved
  keyParameters = {
    ephemeral = false;
    preauthorized = true;
  };
  upFlags = [ "--advertise-tags=tag:fleet" ];
in
{
  options.features.tailscale.exitNode = lib.mkEnableOption "letting others send their internet traffic through this machine";

  config = lib.mkIf config.features.tailscale.enable {
    # The Tailscale app is a Homebrew cask.
    features.darwin.enable = lib.mkIf machine.platform.isDarwin true;

    system =
      if machine.platform.isLinux then
        [
          {
            services.tailscale = {
              enable = true;

              # An exit node needs IP forwarding.
              useRoutingFeatures = if exitNode then "server" else "none";

              # Applied on every boot with tailscale set.
              extraSetFlags = [ "--ssh" ] ++ lib.optional exitNode "--advertise-exit-node";
            };
          }
        ]
        # logs in when it needs to
        ++ lib.optional hasSecrets (
          { config, ... }:
          {
            sops.secrets.tailscale = { };
            services.tailscale = {
              authKeyFile = config.sops.secrets.tailscale.path;
              authKeyParameters = keyParameters;
              # with what tailscale set sets, which up would otherwise refuse
              extraUpFlags = upFlags ++ config.services.tailscale.extraSetFlags;
            };
          }
        )
      else if !(import ./fleet-access/roles.nix).servesFleet config.features then
        { homebrew.casks = [ "tailscale-app" ]; }
      else
        [
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
          )
        ]
        # logs in when it needs to, as NixOS does with authKeyFile
        ++ lib.optional hasSecrets (
          { config, ... }:
          let
            tailscale = "${config.services.tailscale.package}/bin/tailscale";
            parameters = lib.concatStringsSep "&" (
              lib.mapAttrsToList (name: value: "${name}=${lib.boolToString value}") keyParameters
            );
          in
          {
            sops.secrets.tailscale = { };
            launchd.daemons.tailscale-up.serviceConfig = {
              ProgramArguments = [
                "${pkgs.writeShellScript "tailscale-up" ''
                  # fails, and launchd runs it again, until tailscaled is up
                  set -o pipefail
                  state=$(${tailscale} status --json --peers=false | ${lib.getExe pkgs.jq} -r .BackendState) || exit 1
                  case $state in
                    NeedsLogin) exec ${tailscale} up --auth-key "$(cat ${config.sops.secrets.tailscale.path})?${parameters}" ${
                      lib.escapeShellArgs (upFlags ++ [ "--ssh" ])
                    } ;;
                    NoState) exit 1 ;;
                  esac
                ''}"
              ];
              RunAtLoad = true;
              KeepAlive.SuccessfulExit = false;
              StandardErrorPath = "/var/log/tailscale-up.log";
            };
          }
        );
  };
}
