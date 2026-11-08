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
#
# The SSH client settings for logging in to the others are in features/ssh.
{ lib, machine, ... }:
{
  tags = [ "base" ];

  system = lib.optionals machine.servesFleet [
    # Both platforms: Nix trusts the user.
    {
      users.groups.fleet-servant = { };
      nix.settings.trusted-users = [ "fleet-servant" ];
    }
    (
      if machine.platform.isLinux then
        {
          users.users.fleet-servant = {
            isSystemUser = true;
            group = "fleet-servant";
            # Tailscale SSH runs nix-daemon --stdio in its shell.
            useDefaultShell = true;
          };
        }
      else
        {
          # nix-darwin only creates the users and groups it's told it
          # manages, and they need fixed ids.
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
    )
  ];
}
