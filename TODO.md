# TODO

## Build aarch64-linux on the Mac mini's Linux VM from the other machines

The macmini runs the linux-builder VM (the `linux-builder` tag in [flake.nix](flake.nix)), but only the macmini itself can use it. The other machines have nowhere to build aarch64-linux. Waiting on the Mac mini to test with.

### Why the macmini can't just advertise aarch64-linux

fleet-servant is trusted, so Nix sends builds to it with `buildDerivation`. That copies the inputs but not the `.drv` (Nix 2.34, `src/nix/build-remote/build-remote.cc`). A builder only passes a build on to its own builders when the `.drv` is in its store (`src/libstore/build/derivation-building-goal.cc`, in `tryBuildHook`). So the macmini would try aarch64-linux itself and fail.

### Plan

Relay through the macmini straight to the VM's nix-daemon, using Nix's `remote-program` store setting. This is about 50 lines, all in [features/fleet-builders](features/fleet-builders).

```
macbook nix ──Tailscale SSH──▶ macmini (fleet-servant)
                                  │ linux-builder-relay
                                  └──ssh, localhost:31022──▶ VM nix-daemon
```

1. **Relay script** on a builder Mac with the VM, in systemPackages:

   ```sh
   exec ssh -i /var/lib/fleet-servant/linux-builder_ed25519 \
     -o StrictHostKeyChecking=accept-new linux-builder nix-daemon "$@"
   ```

   nix-darwin's `Host linux-builder` entry in ssh_config.d already gives localhost:31022 and the user `builder`.

2. **Copy of the VM's key** for fleet-servant (mode 600), made by a launchd daemon with `RunAtLoad` and `WatchPaths = [ "/etc/nix/builder_ed25519" ]`. The VM creates that key, root:nixbld 600, the first time it starts, so activation can't copy it.

3. **A second builder entry** for the macmini on every other machine:

   ```nix
   {
     hostName = "${machine.address}?remote-program=/run/current-system/sw/bin/linux-builder-relay";
     sshUser = "fleet-servant";
     protocol = "ssh-ng";
     systems = [ "aarch64-linux" ];
     maxJobs = 4; # the VM's; keep it in one place
     speedFactor = 3;
     supportedFeatures = [ "benchmark" "big-parallel" ];
   }
   ```

### To check

- [ ] `?remote-program=…` lands unchanged in `/etc/nix/machines` (`nix eval` can check this before deploying)
- [ ] Tailscale SSH passes the build traffic through cleanly
- [ ] the first deploy works, before the VM has made its key
- [ ] build something from the macbook: `nix build nixpkgs#legacyPackages.aarch64-linux.hello --rebuild -L`
