# TODO

## Check the macbook's Linux VM builds aarch64-linux for the other machines

The macbook (tagged `linux-builder` in [flake.nix](flake.nix)) runs the VM, and the others, and CI's aarch64-linux job, build on it through `linux-builder-relay` (see [features/fleet-builders](features/fleet-builders)).

- [x] `?remote-program=…` lands unchanged in `/etc/nix/machines`
- [x] after switching the macbook, `/var/lib/fleet-servant/linux-builder_ed25519` exists
- [ ] Tailscale SSH passes the build traffic through cleanly: CI's "build aarch64-linux" job says "Building on macbook" (the macbook can't test it on itself: its connections to its own tailnet address skip tailscaled)
- [ ] something actually builds on it, from CI or another machine: `nix build nixpkgs#legacyPackages.aarch64-linux.hello --rebuild -L`
- [ ] the first deploy works on a Mac whose VM hasn't made its key yet (the macmini, when it gets the tag)

Once the macmini is set up, move the `linux-builder` tag to it. The VM can use up to 8 GB of the macbook's memory, and runs all the time.
