# Building on other machines. A machine whose configuration in flake.nix has
# a builder setting builds for the others: every system sends it builds for
# its platform, over the tailnet. One that's off or away is skipped, and the
# build goes to another builder, or is built locally if it can be. A Mac
# tagged linux-builder also runs a Linux VM to build aarch64-linux itself.
#
# Builds go in as the nix-remote user (see nix-remote.nix), which Nix on the
# builder trusts to build what it's sent.
{
  hostname,
  inputs,
  lib,
  platform,
  tags,
  ...
}:
let
  # The other machines that build, read from their configurations (make.nix
  # keeps each one's builder setting and platform in its dotfiles attribute).
  builders = lib.filterAttrs (
    name: configuration: name != hostname && configuration.dotfiles.builder != null
  ) (inputs.self.nixosConfigurations // inputs.self.darwinConfigurations);

  # The platforms a builder builds for: its own, and the 32-bit one an x86_64
  # Linux machine runs too.
  systemsOf = system: [ system ] ++ lib.optional (system == "x86_64-linux") "i686-linux";
in
{
  tags = [ "base" ];

  system =
    lib.optional (builders != { }) {
      nix.distributedBuilds = true;
      nix.buildMachines = lib.mapAttrsToList (name: configuration: {
        hostName = name;
        sshUser = "nix-remote";
        protocol = "ssh-ng";
        systems = systemsOf configuration.dotfiles.platform;
        inherit (configuration.dotfiles.builder) maxJobs speedFactor;
        # What builds can ask for: lots of cores, and for Linux, a VM
        # (nixos-test, kvm).
        supportedFeatures = [
          "benchmark"
          "big-parallel"
        ]
        ++ lib.optionals (lib.hasSuffix "-linux" configuration.dotfiles.platform) [
          "nixos-test"
          "kvm"
        ];
      }) builders;

      # A builder downloads what it can from the caches itself, rather than
      # having this machine upload it.
      nix.settings.builders-use-substitutes = true;
    }
    ++ lib.optional (platform.isDarwin && lib.elem "linux-builder" tags) {
      # A NixOS VM that builds aarch64-linux natively. It adds itself to the
      # machines builds can go to.
      nix.linux-builder = {
        enable = true;
        # Start from a clean VM every time it starts.
        ephemeral = true;
        maxJobs = 4;
        config.virtualisation = {
          cores = 6;
          darwin-builder = {
            memorySize = 8 * 1024;
            diskSize = 40 * 1024;
          };
        };
      };
    };
}
