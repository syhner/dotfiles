# Secrets in secrets/, encrypted with sops, decrypted by sops-nix on activation
# into /run/secrets, never the store. Each machine opens them with its own age
# key, made once (see the README), and .sops.yaml lists who can open which file
# (see nix/sops.nix).
{
  config,
  inputs,
  lib,
  machine,
  pkgs,
  ...
}:
let
  cfg = config.features.secrets;
in
{
  options.features.secrets = {
    ageKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "This machine's age public key, from /var/lib/sops-nix/key.txt. null until it has one.";
    };

    active = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      default = cfg.enable && cfg.ageKey != null;
      description = "Whether this machine has its secrets, for the features that use them.";
    };
  };

  config = lib.mkIf cfg.enable {
    # sops edits the secrets, age-keygen makes a machine's key
    packages = [
      pkgs.age
      pkgs.sops
    ];

    system = lib.optional cfg.active {
      imports = [
        inputs.sops-nix.${if machine.platform.isDarwin then "darwinModules" else "nixosModules"}.sops
      ];

      sops = {
        defaultSopsFile = ../secrets/fleet.yaml;
        age.keyFile = "/var/lib/sops-nix/key.txt";
        # only the key above, not the SSH host keys
        age.sshKeyPaths = [ ];
        gnupg.sshKeyPaths = [ ];
      };
    };
  };
}
