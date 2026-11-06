# The fleet-servant user, which the other machines log in as, over Tailscale
# SSH: to send builds (fleet-builders.nix), and to download from and copy to
# caches (fleet-substituters.nix). It's on every machine that's a builder or
# a substituter: the ones that serve the fleet (machine.servesFleet). Nix
# trusts it, so it can build what it's sent and add what it's copied, which
# isn't signed. That makes every machine allowed to log in as it trusted by
# every other.
#
# Tailscale SSH means there are no keys to share. The tailnet policy decides
# who may log in: only the fleet's machines, each logged in with
# --advertise-tags=tag:fleet, and without the browser check, which a
# background build can't answer:
#
#   "tagOwners": { "tag:fleet": ["autogroup:admin"] },
#   "ssh": [
#     {
#       "action": "accept",
#       "src": ["tag:fleet"],
#       "dst": ["tag:fleet"],
#       "users": ["fleet-servant"]
#     }
#   ]
#
# A tagged machine belongs to the tag rather than to you, so the default rule
# letting you SSH in to your own devices no longer covers it: SSH in as
# yourself needs its own rule, with "dst": ["tag:fleet"].
{
  inputs,
  lib,
  machine,
  ...
}:
let
  # The other machines with this user, read from their configurations
  # (make.nix puts each one's machine attribute on it).
  remotes = lib.filterAttrs (
    name: configuration: name != machine.hostname && configuration.machine.servesFleet
  ) (inputs.self.nixosConfigurations // inputs.self.darwinConfigurations);

  # Both platforms: Nix trusts the user.
  trusted = {
    users.groups.fleet-servant = { };
    nix.settings.trusted-users = [ "fleet-servant" ];
  };
in
{
  tags = [ "base" ];

  system =
    # Logging in to the others, at their tailnet addresses (machine.address).
    # The nix daemon connects in the background, so it can't be asked to
    # trust a host key: the tailnet already proves which machine it is, so
    # the first key it sees is trusted. One that's off is given up on after a
    # few seconds rather than holding anything up.
    lib.optional (remotes != { }) {
      programs.ssh.extraConfig = ''
        Host ${toString (lib.mapAttrsToList (_: configuration: configuration.machine.address) remotes)}
          StrictHostKeyChecking accept-new
          ConnectTimeout 5
      '';
    }
    ++ lib.optionals (machine.servesFleet && machine.platform.isLinux) [
      trusted
      {
        users.users.fleet-servant = {
          isSystemUser = true;
          group = "fleet-servant";
          # Tailscale SSH runs nix-daemon --stdio in its shell.
          useDefaultShell = true;
        };
      }
    ]
    ++ lib.optionals (machine.servesFleet && machine.platform.isDarwin) [
      trusted
      {
        # nix-darwin only creates the users and groups it's told it manages,
        # and they need fixed ids.
        users.knownUsers = [ "fleet-servant" ];
        users.knownGroups = [ "fleet-servant" ];
        users.groups.fleet-servant.gid = 550;
        users.users.fleet-servant = {
          uid = 550;
          gid = 550;
          home = "/var/lib/fleet-servant";
          createHome = true;
          # Tailscale SSH runs nix-daemon --stdio in its shell.
          shell = "/bin/zsh";
          isHidden = true;
        };
      }
    ];
}
