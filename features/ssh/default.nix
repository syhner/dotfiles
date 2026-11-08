# SSH: the client, gpg-agent as its agent, and the OpenSSH server. Most
# machines are reached with Tailscale SSH instead (see tailscale.nix), which
# has neither passwords nor keys: the tailnet policy decides who can log in
# (see fleet-access.nix).
{
  lib,
  machine,
  otherMachines,
  settings,
  symlinkToCheckout,
  ...
}:
let
  hasTag = tag: lib.elem tag machine.tags;

  # The machines with the fleet-servant user (see fleet-access.nix).
  remotes = builtins.filter (other: other.servesFleet) otherMachines;
in
{
  tags = [
    "base"
    "nixos"
    "utm-guest"
  ];

  home =
    lib.optional (hasTag "base") {
      # gpg-agent offers the GPG-backed key (see features/gpg).
      services.gpg-agent = {
        enableSshSupport = true;
        sshKeys = [ settings.sshKeygrip ];
      };
    }
    ++ lib.optional (hasTag "base" && machine.platform.isDarwin) {
      home.file.".ssh/config".source = symlinkToCheckout ./ssh_config;
    };

  system =
    # Logging in to the others, at their tailnet addresses (machine.address).
    # The nix daemon connects in the background, so it can't be asked to
    # trust a host key: the tailnet already proves which machine it is, so
    # the first key it sees is trusted. One that's off is given up on after a
    # few seconds rather than holding anything up.
    lib.optional (hasTag "base" && remotes != [ ]) {
      programs.ssh.extraConfig = ''
        Host ${toString (map (remote: remote.address) remotes)}
          StrictHostKeyChecking accept-new
          ConnectTimeout 5
      '';
    }
    # On a machine that runs OpenSSH, logging in only with a key, root
    # included: no password, and no keyboard-interactive, which asks for one
    # through PAM.
    ++ lib.optional (hasTag "nixos") {
      users.users.root.openssh.authorizedKeys.keys = [ settings.sshPublicKey ];
      services.openssh.settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    }
    # A UTM VM runs OpenSSH, with its port open. The user's key is the
    # GPG-backed one gpg-agent offers on the Mac. If it's unavailable, the UTM
    # console and Tailscale SSH still work.
    ++ lib.optional (hasTag "utm-guest") {
      services.openssh.enable = true;
      users.users.${settings.username}.openssh.authorizedKeys.keys = [ settings.sshPublicKey ];
      networking.firewall.allowedTCPPorts = [ 22 ];
    };
}
