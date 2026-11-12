# What each of the given machines builds for the others: the machine itself,
# if it has a builder setting, and a builder Mac's Linux VM, reached through
# the Mac with remoteProgram in place of nix-daemon. default.nix and
# .github/ci.nix both build from this.
lib: machines:
let
  linuxVM = import ./linux-vm.nix lib;
  withBuilder = builtins.filter (machine: machine.builder != null) machines;
in
map (machine: {
  inherit machine;
  inherit (machine.builder) maxJobs speedFactor;
  system = machine.platform.system;
  supportedFeatures = import ./builder-features.nix lib machine.platform;
  remoteProgram = null;
}) withBuilder
++ map (mac: {
  machine = mac;
  inherit (mac.builder) speedFactor;
  inherit (linuxVM)
    system
    maxJobs
    supportedFeatures
    remoteProgram
    ;
}) (builtins.filter linuxVM.runsOn withBuilder)
