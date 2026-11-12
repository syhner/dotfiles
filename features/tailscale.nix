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

  # applied on every boot with tailscale set
  setFlags = [ "--ssh" ] ++ lib.optional exitNode "--advertise-exit-node";
  # with what tailscale set sets, which up would otherwise refuse; --reset drops
  # anything set by hand
  upFlags = [
    "--reset"
    "--advertise-tags=tag:fleet"
  ]
  ++ setFlags;

  # for an OAuth client secret: a lasting node, approved
  keyParameters = {
    ephemeral = false;
    preauthorized = true;
  };
  keyQuery = lib.concatStringsSep "&" (
    lib.mapAttrsToList (
      name: value: "${name}=${if lib.isBool value then lib.boolToString value else toString value}"
    ) keyParameters
  );

  # the OAuth client secret, in secrets/fleet.yaml
  loginSecret.sops.secrets.tailscale = { };
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

              extraSetFlags = setFlags;
            };
          }
        ]
        # logs in when it needs to
        ++ lib.optionals hasSecrets [
          loginSecret
          (
            { config, ... }:
            {
              services.tailscale = {
                authKeyFile = config.sops.secrets.tailscale.path;
                authKeyParameters = keyParameters;
                extraUpFlags = upFlags;
              };
            }
          )
        ]
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

              # Set on boot, as NixOS does with extraSetFlags. tailscale set
              # works before logging in too; run before tailscaled is up, it
              # fails and launchd runs it again.
              launchd.daemons.tailscale-set.serviceConfig = {
                ProgramArguments = [
                  "${config.services.tailscale.package}/bin/tailscale"
                  "set"
                ]
                ++ setFlags;
                RunAtLoad = true;
                KeepAlive.SuccessfulExit = false;
                StandardErrorPath = "/var/log/tailscale-set.log";
              };
            }
          )
        ]
        # logs in when it needs to, as NixOS does with authKeyFile
        ++ lib.optionals hasSecrets [
          loginSecret
          (
            { config, ... }:
            let
              tailscale = "${config.services.tailscale.package}/bin/tailscale";
              secret = config.sops.secrets.tailscale.path;
            in
            {
              launchd.daemons.tailscale-up.serviceConfig = {
                ProgramArguments = [
                  "${pkgs.writeShellScript "tailscale-up" ''
                    # fails, and launchd runs it again, until sops-nix has written
                    # the secret, tailscaled is up, and it's logged in
                    set -o pipefail
                    [ -s ${secret} ] || exit 1
                    state=$(${tailscale} status --json --peers=false | ${lib.getExe pkgs.jq} -r .BackendState) || exit 1
                    case $state in
                      NeedsLogin | NeedsMachineAuth | Stopped)
                        exec ${tailscale} up --auth-key "$(cat ${secret})?${keyQuery}" ${lib.escapeShellArgs upFlags}
                        ;;
                      Running) exit 0 ;;
                      *) exit 1 ;;
                    esac
                  ''}"
                ];
                RunAtLoad = true;
                KeepAlive.SuccessfulExit = false;
                # not sending the secret every 10 seconds when up fails
                ThrottleInterval = 30;
                StandardErrorPath = "/var/log/tailscale-up.log";
              };
            }
          )
        ];
  };
}
