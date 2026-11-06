# Binary caches of my own, with Harmonia
# (https://github.com/nix-community/harmonia). Each machine whose
# configuration in flake.nix has a substituter setting serves its Nix store,
# on the tailnet, as a cache. Every other system downloads from all of them,
# in the order of their priorities, and copies its new system to each, so a
# package is built once for every machine. They're private, so unlike the
# Cachix cache they can hold unfree packages.
#
# Nothing is signed. Nix trusts what a cache serves (trusted=1) for where it
# comes from: the cache's tailnet address (machine.address), which only the
# tailnet resolves, and where WireGuard proves which machine answered.
# Downloads are over plain HTTP, inside the tunnel, and compressed. Keep to
# the full address: at a bare hostname, with Tailscale down, whatever
# answered on the LAN would be trusted.
#
# Copies go in over Tailscale SSH, as the fleet-servant user (see
# fleet-access.nix), which Nix on the substituter trusts to add what it's
# sent. A substituter that's also a builder serves what it built for the
# others: it's in its store already.
#
# The cache is the machine's store, so its garbage collection empties the
# cache too: what's copied there isn't kept alive by anything. Don't collect
# garbage on it automatically.
{
  inputs,
  lib,
  machine,
  pkgs,
  ...
}:
let
  # Not 5000, which AirPlay Receiver takes on a Mac.
  port = toString 5050;

  # The other substituters, read from their configurations (make.nix puts
  # each one's machine attribute on it).
  servers = lib.filterAttrs (
    name: configuration: name != machine.hostname && configuration.machine.substituter != null
  ) (inputs.self.nixosConfigurations // inputs.self.darwinConfigurations);

  # Run on each switch, and on boot, for a switch made while the network was
  # down. Copies the current system to each cache. A cache that's off misses
  # it, until the next switch. With
  # --substitute-on-destination, a cache downloads what it can from the
  # caches itself, so only what was built here is uploaded. One that's off
  # doesn't stop the rest.
  sync =
    nix:
    pkgs.writeShellScript "substituters-sync" ''
      # nix copy runs ssh.
      export PATH=${pkgs.openssh}/bin:$PATH

      ${lib.concatMapStrings (
        { machine, ... }:
        ''
          ${nix}/bin/nix copy --substitute-on-destination --to ssh-ng://fleet-servant@${machine.address} /run/current-system \
            || echo "Couldn't copy to ${machine.hostname}" >&2
        ''
      ) (builtins.attrValues servers)}
    '';

  # What Harmonia serves with. Compression is off by default.
  harmoniaSettings = {
    enable_compression = true;
  };
in
{
  tags = [ "base" ];

  system =
    lib.optional (servers != { }) {
      nix.settings = {
        # A lower priority is asked first: cache.nixos.org is 40 and Cachix 41.
        extra-substituters = lib.mapAttrsToList (
          _: configuration:
          "http://${configuration.machine.address}:${port}?priority=${toString configuration.machine.substituter.priority}&trusted=1"
        ) servers;
        # With a substituter off, give up on it quickly rather than holding up
        # every build.
        connect-timeout = 5;
      };
    }
    ++ lib.optional (servers != { } && machine.platform.isLinux) (
      { config, ... }:
      {
        # Started by the path and timer, in the background, so a switch
        # doesn't wait. The path doesn't fire on boot: the system's already
        # there when it starts watching.
        systemd.services.substituters-sync = {
          description = "Copy the current system to the fleet's caches";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = sync config.nix.package;
          };
        };
        systemd.paths.substituters-sync = {
          wantedBy = [ "multi-user.target" ];
          pathConfig.PathChanged = "/run/current-system";
        };
        systemd.timers.substituters-sync = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "1min";
          };
        };
      }
    )
    ++ lib.optional (servers != { } && machine.platform.isDarwin) (
      { config, ... }:
      {
        launchd.daemons.substituters-sync.serviceConfig = {
          ProgramArguments = [ "${sync config.nix.package}" ];
          WatchPaths = [ "/run/current-system" ];
          RunAtLoad = true;
          StandardErrorPath = "/var/log/substituters-sync.log";
        };
      }
    )
    # Serving, on NixOS with its module, to the tailnet only.
    ++ lib.optional (machine.substituter != null && machine.platform.isLinux) {
      services.harmonia.cache = {
        enable = true;
        settings = harmoniaSettings // {
          bind = "[::]:${port}";
        };
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ (lib.toInt port) ];
    }
    # Serving, on a Mac, with a launchd service of its own (nix-darwin has no
    # module), as its own user. It listens locally, and tailscale serve
    # publishes it on the tailnet: nix-darwin can't limit a port to the
    # tailnet. A Mac substituter runs the open source tailscaled (see
    # tailscale.nix), whose tailscale command this uses.
    ++ lib.optional (machine.substituter != null && machine.platform.isDarwin) (
      { config, ... }:
      let
        tailscale = "${config.services.tailscale.package}/bin/tailscale";
      in
      {
        users.knownUsers = [ "_harmonia" ];
        users.knownGroups = [ "_harmonia" ];
        users.groups._harmonia.gid = 551;
        users.users._harmonia = {
          uid = 551;
          gid = 551;
          home = "/var/lib/harmonia";
          createHome = true;
          shell = "/usr/bin/false";
          isHidden = true;
        };

        launchd.daemons.harmonia.serviceConfig = {
          ProgramArguments = [ (lib.getExe' pkgs.harmonia "harmonia-cache") ];
          UserName = "_harmonia";
          EnvironmentVariables = {
            CONFIG_FILE = toString (
              (pkgs.formats.toml { }).generate "harmonia.toml" (
                harmoniaSettings
                // {
                  bind = "127.0.0.1:${port}";
                }
              )
            );
            HOME = "/var/lib/harmonia";
          };
          RunAtLoad = true;
          KeepAlive = true;
          StandardErrorPath = "/var/log/harmonia.log";
        };

        # Publishes the cache once Tailscale is logged in, which may be long
        # after boot, and again if that fails. Tailscale keeps the setting.
        launchd.daemons.harmonia-publish.serviceConfig = {
          ProgramArguments = [
            "${pkgs.writeShellScript "harmonia-publish" ''
              ${tailscale} wait
              exec ${tailscale} serve --bg --tcp ${port} tcp://127.0.0.1:${port}
            ''}"
          ];
          RunAtLoad = true;
          KeepAlive.SuccessfulExit = false;
          StandardErrorPath = "/var/log/harmonia-publish.log";
        };
      }
    );
}
