# The user the other machines in the fleet log in as, over Tailscale SSH: to
# send builds (remote-builds.nix) and to copy to caches (harmonia.nix). It's
# on every machine that's a builder or a substituter. Nix trusts it, so it can
# build what it's sent and add what it's copied, which isn't signed. That
# makes every machine allowed to log in as it trusted by every other.
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
#       "users": ["nix-remote"]
#     }
#   ]
#
# A tagged machine belongs to the tag rather than to you, so the default rule
# letting you SSH in to your own devices no longer covers it: SSH in as
# yourself needs its own rule, with "dst": ["tag:fleet"].
{
  builder,
  hostname,
  inputs,
  lib,
  platform,
  substituter,
  ...
}:
let
  # The other machines with this user, read from their configurations
  # (make.nix keeps each one's settings in its dotfiles attribute).
  remotes = lib.filterAttrs (
    name: configuration:
    name != hostname
    && (configuration.dotfiles.builder != null || configuration.dotfiles.substituter != null)
  ) (inputs.self.nixosConfigurations // inputs.self.darwinConfigurations);

  hasUser = builder != null || substituter != null;

  # Both platforms: Nix trusts the user.
  trusted = {
    users.groups.nix-remote = { };
    nix.settings.trusted-users = [ "nix-remote" ];
  };
in
{
  tags = [ "base" ];

  system =
    # Logging in to the others. The nix daemon connects in the background,
    # so it can't be asked to trust a host key: the tailnet already proves
    # which machine it is, so the first key it sees is trusted. One that's off
    # is given up on after a few seconds rather than holding anything up.
    lib.optional (remotes != { }) {
      programs.ssh.extraConfig = ''
        Host ${lib.concatStringsSep " " (builtins.attrNames remotes)}
          StrictHostKeyChecking accept-new
          ConnectTimeout 5
      '';
    }
    ++ lib.optionals (hasUser && platform.isLinux) [
      trusted
      {
        users.users.nix-remote = {
          isSystemUser = true;
          group = "nix-remote";
          # Tailscale SSH runs nix-daemon --stdio in its shell.
          useDefaultShell = true;
        };
      }
    ]
    ++ lib.optionals (hasUser && platform.isDarwin) [
      trusted
      {
        # nix-darwin only creates the users and groups it's told it manages,
        # and they need fixed ids.
        users.knownUsers = [ "nix-remote" ];
        users.knownGroups = [ "nix-remote" ];
        users.groups.nix-remote.gid = 550;
        users.users.nix-remote = {
          uid = 550;
          gid = 550;
          home = "/var/lib/nix-remote";
          createHome = true;
          # Tailscale SSH runs nix-daemon --stdio in its shell.
          shell = "/bin/zsh";
          isHidden = true;
        };
      }
    ];
}
