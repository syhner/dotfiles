# The Linux VM a builder Mac tagged linux-builder runs (see default.nix), and
# how the others reach it, which builders.nix uses too.
lib: {
  runsOn =
    machine:
    machine.builder != null && machine.platform.isDarwin && lib.elem "linux-builder" machine.tags;
  system = "aarch64-linux";
  maxJobs = 4;
  # Not kvm: it has no nested virtualisation, so no NixOS tests.
  supportedFeatures = [
    "benchmark"
    "big-parallel"
  ];
  # What the others run on the Mac in place of nix-daemon.
  remoteProgram = "/run/current-system/sw/bin/linux-builder-relay";
}
