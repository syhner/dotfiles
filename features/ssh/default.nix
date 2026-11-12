# SSH: the client, gpg-agent as its agent, and the OpenSSH server settings.
# Most machines are reached with Tailscale SSH instead (see tailscale.nix and
# fleet-access); the UTM guests also run OpenSSH (see features/utm-guest).
{
  config,
  lib,
  machine,
  settings,
  symlinkToCheckout,
  ...
}:
{
  config = lib.mkIf config.features.ssh.enable {
    # gpg-agent is the SSH agent.
    features.gpg.enable = true;

    home = [
      {
        # gpg-agent offers the GPG-backed key (see features/gpg)
        services.gpg-agent = {
          enableSshSupport = true;
          sshKeys = [ settings.sshKeygrip ];
        };
      }
    ]
    # GUI apps on macOS don't get gpg-agent's SSH_AUTH_SOCK
    ++ lib.optional machine.platform.isDarwin {
      home.file.".ssh/config".source = symlinkToCheckout ./ssh_config;
    };

    system = [
      # for the nix daemon, which reaches the fleet as root
      { programs.ssh.extraConfig = import ./tailnet.nix settings; }
    ]
    # Key-only logins, root included, wherever OpenSSH is enabled.
    ++ lib.optional machine.platform.isLinux {
      users.users.root.openssh.authorizedKeys.keys = [ settings.sshPublicKey ];
      users.users.${settings.username}.openssh.authorizedKeys.keys = [ settings.sshPublicKey ];
      services.openssh.settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };
  };
}
