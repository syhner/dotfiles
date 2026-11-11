# What builds sent to a builder can ask for: lots of cores, and for Linux, a VM
lib: platform:
[
  "benchmark"
  "big-parallel"
]
++ lib.optionals platform.isLinux [
  "nixos-test"
  "kvm"
]
