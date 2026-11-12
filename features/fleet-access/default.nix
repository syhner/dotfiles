# The fleet-servant user, which the other machines log in as, over Tailscale
# SSH: to send builds (fleet-builders), and to download from and copy to
# caches (fleet-substituters.nix). It's on every machine that's a builder or
# a substituter: the ones that serve the fleet (roles.nix). Nix trusts it,
# so it can build what it's sent and add what it's copied, which isn't
# signed. That makes every machine allowed to log in as it trusted by every
# other.
#
# Tailscale SSH means there are no keys to share. The tailnet policy decides
# who may log in: only the fleet's machines, each logged in with
# --advertise-tags=tag:fleet, and without the browser check, which a
# background build can't answer:
#
#   "tagOwners": {
#     "tag:fleet": ["autogroup:admin"],
#     "tag:ci": ["autogroup:admin"]
#   },
#   "ssh": [
#     {
#       "action": "accept",
#       "src": ["tag:fleet", "tag:ci"],
#       "dst": ["tag:fleet"],
#       "users": ["fleet-servant"]
#     }
#   ]
#
# tag:ci is CI's machine, for the length of a build job, which builds on the
# fleet's builders (see .github/workflows/ci.yml).
#
# A tagged machine belongs to the tag rather than to you, so the default rule
# letting you SSH in to your own devices no longer covers it: SSH in as
# yourself needs its own rule, with "dst": ["tag:fleet"].
#
# The SSH client settings for logging in to the others are in features/ssh.
{
  config,
  lib,
  machine,
  ...
}:
let
  user = import ./user.nix;
in
{
  config = lib.mkIf config.features.fleet-access.enable {
    # The others log in as fleet-servant with Tailscale SSH.
    features.tailscale.enable = true;

    system = lib.optionals ((import ./roles.nix).servesFleet config.features) [
      # Both platforms: Nix trusts the user.
      {
        users.groups.${user.name} = { };
        nix.settings.trusted-users = [ user.name ];
      }
      (
        if machine.platform.isLinux then
          {
            users.users.${user.name} = {
              isSystemUser = true;
              group = user.name;
              # Tailscale SSH runs nix-daemon --stdio in its shell.
              useDefaultShell = true;
            };
          }
        else
          {
            # nix-darwin only creates the users and groups it's told it
            # manages, and they need fixed ids.
            users.knownUsers = [ user.name ];
            users.knownGroups = [ user.name ];
            users.groups.${user.name}.gid = 550;
            users.users.${user.name} = {
              uid = 550;
              gid = 550;
              inherit (user) home;
              createHome = true;
              # Tailscale SSH runs nix-daemon --stdio in its shell.
              shell = "/bin/zsh";
              isHidden = true;
            };
          }
      )
    ];
  };
}
