# Binary caches of my own, with Harmonia
# (https://github.com/nix-community/harmonia). Each machine whose
# configuration in flake.nix has a substituter setting serves its Nix store,
# on the tailnet, as a cache. Every other system downloads from all of them,
# in the order of their priorities, and after each switch copies its new
# system to each, so a package is built once for every machine. They're
# private, so unlike the Cachix cache they can hold unfree packages.
#
# Copies go in as the nix-remote user (see nix-remote.nix), which Nix on the
# substituter trusts to add what it's sent. A substituter that's also a
# builder serves what it built for the others, too: it's in its store already.
#
# Nothing changes until a substituter has a signing key, and its public half
# is set as substituter.publicKey in flake.nix. On the machine:
#
#   sudo mkdir -p /var/lib/secrets
#   sudo sh -c "umask 077; nix key generate-secret --key-name $(hostname)-1 > /var/lib/secrets/harmonia"
#   sudo nix key convert-secret-to-public < /var/lib/secrets/harmonia
#
# On a Mac, also let the cache read the key, and publish it on the tailnet
# (nix-darwin can't limit a port to the tailnet, so it only listens locally):
#
#   sudo chown _harmonia /var/lib/secrets/harmonia
#   sudo tailscale serve --bg --tcp 5050 tcp://127.0.0.1:5050
#
# The cache is the machine's store, so its garbage collection empties the
# cache too: what's copied there isn't kept alive by anything. Don't collect
# garbage on it automatically.
{
  hostname,
  inputs,
  lib,
  pkgs,
  platform,
  substituter,
  ...
}:
let
  # Not 5000, which AirPlay Receiver takes on a Mac.
  port = 5050;

  # Where a substituter's signing key is.
  keyFile = "/var/lib/secrets/harmonia";

  # The other substituters, once they have a key, read from their
  # configurations (make.nix keeps each one's substituter setting in its
  # dotfiles attribute).
  servers = lib.filterAttrs (
    name: configuration:
    name != hostname
    && configuration.dotfiles.substituter != null
    && configuration.dotfiles.substituter.publicKey != null
  ) (inputs.self.nixosConfigurations // inputs.self.darwinConfigurations);

  # Copies this machine's current system to each substituter. With
  # --substitute-on-destination, the substituter downloads what it can from
  # the caches itself, so only what was built here is uploaded. One that's
  # off doesn't stop the copies to the rest.
  push =
    nix:
    lib.concatMapStringsSep "\n" (
      name:
      "${nix}/bin/nix copy --substitute-on-destination --to ssh-ng://nix-remote@${name} /run/current-system"
      + " || echo 'Couldn'\\''t copy to ${name}' >&2"
    ) (builtins.attrNames servers);

  # What this machine serves with, if it's a substituter. Each cache tells
  # the others its priority: a lower number is asked first. cache.nixos.org
  # is 40 and Cachix 41.
  settings = lib.optionalAttrs (substituter != null) {
    inherit (substituter) priority;
  };
in
{
  tags = [ "base" ];

  system =
    lib.optional (servers != { }) {
      nix.settings = {
        extra-substituters = lib.mapAttrsToList (name: _: "http://${name}:${toString port}") servers;
        extra-trusted-public-keys = lib.mapAttrsToList (
          _: configuration: configuration.dotfiles.substituter.publicKey
        ) servers;
        # Away from the tailnet, or with a substituter off, give up on it
        # quickly rather than holding up every build.
        connect-timeout = 5;
      };
    }
    # Pushes after each switch, in the background, so the switch doesn't wait.
    ++ lib.optional (servers != { } && platform.isLinux) (
      { config, ... }:
      {
        systemd.paths.harmonia-push = {
          wantedBy = [ "multi-user.target" ];
          pathConfig.PathChanged = "/run/current-system";
        };
        systemd.services.harmonia-push = {
          description = "Copy the current system to the Harmonia caches";
          serviceConfig.Type = "oneshot";
          script = push config.nix.package;
        };
      }
    )
    ++ lib.optional (servers != { } && platform.isDarwin) (
      { config, ... }:
      {
        launchd.daemons.harmonia-push.serviceConfig = {
          ProgramArguments = [ "${pkgs.writeShellScript "harmonia-push" (push config.nix.package)}" ];
          # On each switch, and on boot.
          WatchPaths = [ "/run/current-system" ];
          RunAtLoad = true;
          StandardErrorPath = "/var/log/harmonia-push.log";
        };
      }
    )
    # Serving, on NixOS with its module, to the tailnet only.
    ++ lib.optional (substituter != null && platform.isLinux) {
      services.harmonia.cache = {
        enable = true;
        signKeyPaths = [ keyFile ];
        settings = settings // {
          bind = "[::]:${toString port}";
        };
      };

      # Until there's a key, there's nothing to sign with.
      systemd.sockets.harmonia.unitConfig.ConditionPathExists = keyFile;
      systemd.services.harmonia.unitConfig.ConditionPathExists = keyFile;

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];
    }
    # Serving, on a Mac, with a launchd service of its own (nix-darwin has no
    # module), as its own user. It listens locally; tailscale serve publishes
    # it on the tailnet.
    ++ lib.optional (substituter != null && platform.isDarwin) {
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
              settings
              // {
                bind = "127.0.0.1:${toString port}";
              }
            )
          );
          SIGN_KEY_PATHS = keyFile;
          HOME = "/var/lib/harmonia";
        };
        # Running, and restarted when it stops, while there's a key.
        KeepAlive.PathState.${keyFile} = true;
        StandardErrorPath = "/var/log/harmonia.log";
      };
    };
}
