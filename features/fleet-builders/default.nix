# Building on other machines. A machine whose configuration in flake.nix has
# a builder setting builds for the others: every system sends it builds for
# its platform, over the tailnet. One that's off or away is skipped, and the
# build goes to another builder, or is built locally if it can be.
#
# A builder Mac tagged linux-builder also runs a Linux VM to build
# aarch64-linux, for itself and the others. They can't just send it
# aarch64-linux builds: Nix sends a build to a trusted builder without its
# .drv, and a builder only passes on to its own builders a build whose .drv
# it has, so the Mac would try it itself and fail. Instead they talk to the
# VM's nix-daemon directly, with the Mac as a relay:
#
#   other machine ──Tailscale SSH──▶ Mac, as fleet-servant
#                                      └─ linux-builder-relay ──SSH──▶ VM nix-daemon
#
# Builds go in as the fleet-servant user (see fleet-access.nix), which Nix on
# the builder trusts to build what it's sent.
{
  lib,
  machine,
  otherMachines,
  pkgs,
  ...
}:
let
  linuxVM = import ./linux-vm.nix lib;

  # The other machines that build. With buildOwnPlatform, not the ones for
  # this machine's own platform: Nix sends a build to any builder with a free
  # slot, however much faster this machine is, and only builds it here when
  # there's none.
  builders = builtins.filter (
    other:
    other.builder != null
    && !(machine.buildOwnPlatform && other.platform.system == machine.platform.system)
  ) otherMachines;

  # The other Macs' VMs, unless this machine has its own.
  linuxVMs = lib.optionals (!linuxVM.runsOn machine) (builtins.filter linuxVM.runsOn otherMachines);

  # The platforms a builder builds for: its own, and the 32-bit one an x86_64
  # Linux machine runs too.
  systemsOf = system: [ system ] ++ lib.optional (system == "x86_64-linux") "i686-linux";

  builderFeatures = import ./builder-features.nix lib;

  # The VM's key, which fleet-servant can't read, copied for it.
  vmKey = "/var/lib/fleet-servant/linux-builder_ed25519";

  # nix-darwin's Host linux-builder entry gives the VM's address and user.
  relay = pkgs.writeShellScriptBin (baseNameOf linuxVM.remoteProgram) ''
    exec /usr/bin/ssh -i ${vmKey} -o StrictHostKeyChecking=accept-new \
      linux-builder nix-daemon "$@"
  '';
in
{
  tags = [ "base" ];

  system =
    lib.optional (builders != [ ] || linuxVMs != [ ]) {
      nix.distributedBuilds = true;
      nix.buildMachines =
        map (builder: {
          hostName = builder.address;
          sshUser = "fleet-servant";
          protocol = "ssh-ng";
          systems = systemsOf builder.platform.system;
          inherit (builder.builder) maxJobs speedFactor;
          supportedFeatures = builderFeatures builder.platform;
        }) builders
        ++ map (mac: {
          hostName = "${mac.address}?remote-program=${linuxVM.remoteProgram}";
          sshUser = "fleet-servant";
          protocol = "ssh-ng";
          systems = [ linuxVM.system ];
          inherit (linuxVM) maxJobs supportedFeatures;
          inherit (mac.builder) speedFactor;
        }) linuxVMs;

      # A builder downloads what it can from the caches itself, rather than
      # having this machine upload it.
      nix.settings.builders-use-substitutes = true;
    }
    ++ lib.optional (linuxVM.runsOn machine) {
      # A NixOS VM that builds aarch64-linux natively. It adds itself to the
      # machines builds can go to.
      nix.linux-builder = {
        enable = true;
        # Start from a clean VM every time it starts.
        ephemeral = true;
        inherit (linuxVM) maxJobs;
        config.virtualisation = {
          cores = 6;
          darwin-builder = {
            memorySize = 8 * 1024;
            diskSize = 40 * 1024;
          };
        };
      };

      environment.systemPackages = [ relay ];

      # The VM makes its key the first time it starts, so activation can't
      # copy it.
      launchd.daemons.linux-builder-key.serviceConfig = {
        ProgramArguments = [
          "/bin/sh"
          "-c"
          ''
            [ -e /etc/nix/builder_ed25519 ] || exit 0
            /usr/bin/install -m 600 -o fleet-servant -g fleet-servant \
              /etc/nix/builder_ed25519 ${vmKey}
          ''
        ];
        WatchPaths = [ "/etc/nix/builder_ed25519" ];
        RunAtLoad = true;
        StandardErrorPath = "/var/log/linux-builder-key.log";
      };
    };
}
