# What each of the given machines builds for the others: the machine itself,
# if it's a builder, and a builder Mac's Linux VM, reached through
# the Mac with remoteProgram in place of nix-daemon. default.nix and
# .github/ci.nix both build from this.
lib: machines:
let
  linuxVM = import ./linux-vm.nix lib;
  roles = import ../fleet-access/roles.nix;
  withBuilder = builtins.filter (machine: roles.builds machine.features) machines;
in
map (machine: {
  inherit machine;
  inherit (machine.features.fleet-builders.builder) maxJobs speedFactor;
  system = machine.platform.system;
  supportedFeatures = import ./builder-features.nix lib machine.platform;
  remoteProgram = null;
}) withBuilder
++ map (mac: {
  machine = mac;
  inherit (mac.features.fleet-builders.builder) speedFactor;
  inherit (linuxVM)
    system
    maxJobs
    supportedFeatures
    remoteProgram
    ;
}) (builtins.filter linuxVM.runsOn withBuilder)
