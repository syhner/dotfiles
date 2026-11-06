# Building on other machines. A machine whose configuration in flake.nix has
# a builder setting builds for the others: every system sends it builds for
# its platform, over the tailnet. One that's off or away is skipped, and the
# build goes to another builder, or is built locally if it can be. A Mac
# tagged linux-builder also runs a Linux VM to build aarch64-linux itself.
#
# Builds go in as the fleet-servant user (see fleet-access.nix), which Nix on
# the builder trusts to build what it's sent.
{
  inputs,
  lib,
  machine,
  ...
}:
let
  # The other machines that build, read from their configurations (make.nix
  # puts each one's machine attribute on it). With buildOwnPlatform, not the ones
  # for this machine's own platform: Nix sends a build to any builder with a
  # free slot, however much faster this machine is, and only builds it here
  # when there's none.
  builders = lib.filterAttrs (
    name: configuration:
    name != machine.hostname
    && configuration.machine.builder != null
    && !(machine.buildOwnPlatform && configuration.machine.platform.system == machine.platform.system)
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
      nix.buildMachines = lib.mapAttrsToList (_: configuration: {
        hostName = configuration.machine.address;
        sshUser = "fleet-servant";
        protocol = "ssh-ng";
        systems = systemsOf configuration.machine.platform.system;
        inherit (configuration.machine.builder) maxJobs speedFactor;
        # What builds can ask for: lots of cores, and for Linux, a VM
        # (nixos-test, kvm).
        supportedFeatures = [
          "benchmark"
          "big-parallel"
        ]
        ++ lib.optionals configuration.machine.platform.isLinux [
          "nixos-test"
          "kvm"
        ];
      }) builders;

      # A builder downloads what it can from the caches itself, rather than
      # having this machine upload it.
      nix.settings.builders-use-substitutes = true;
    }
    ++ lib.optional (machine.platform.isDarwin && lib.elem "linux-builder" machine.tags) {
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
