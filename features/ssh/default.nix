# SSH: the client, gpg-agent as its agent, and the OpenSSH server settings.
# Most machines are reached with Tailscale SSH instead (see tailscale.nix and
# fleet-access.nix); the UTM guests also run OpenSSH (see features/utm-guest).
{
  lib,
  machine,
  settings,
  symlinkToCheckout,
  ...
}:
{
  tags = [ "base" ];

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
    # tailnet proves who a host is, so the nix daemon trusts its first key
    {
      programs.ssh.extraConfig = ''
        Host *.${settings.tailnet}
          StrictHostKeyChecking accept-new
          ConnectTimeout 5
      '';
    }
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
}
