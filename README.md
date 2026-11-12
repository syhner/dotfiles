# dotfiles

## External setup

### Tailscale

- The tailnet policy in [features/fleet-access](features/fleet-access/default.nix), for remote builds and the shared caches, with its `tag:ci` parts for CI to build on them too
- An OAuth client (Settings → Trust credentials) with the `auth_keys` scope (write) and the `tag:fleet` tag, for a machine with secrets to log itself in. Keep its secret for the first machine that gets its secrets

### GitHub

- `CACHIX_AUTH_TOKEN` repository secret, for CI to push what it builds to the Cachix cache (without it, CI only downloads from it)
- `FLAKE_UPDATE_TOKEN` repository secret, for the weekly `flake.lock` update pull request, and for it to start CI

## Pre-requisites (macOS)

- Install Xcode Command Line Tools (this will give git)

  ```sh
  xcode-select --install
  ```

- Install Rosetta

  ```sh
  softwareupdate --install-rosetta --agree-to-license
  ```

- Give Terminal Full Disk Access

## Setup (macOS / Linux / WSL)

- Install one of:
  - [Nix (the package manager)](https://nixos.org/download/) on macOS, or on a Linux distribution if you just want to manage system packages with Nix
  - [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) on Windows, from a tarball of the `wsl` configuration built on a Linux machine with Nix, in a clone of this repository (or download the release's `nixos.wsl` and switch to `wsl` afterwards)
    ```sh
    sudo nix --extra-experimental-features 'nix-command flakes' run .#nixosConfigurations.wsl.config.system.build.tarballBuilder
    # then, on Windows, with the nixos.wsl it made
    wsl --install --from-file nixos.wsl
    ```
  - [NixOS (the Linux distribution)](https://nixos.org/download/#nixos-iso) if you want to manage your system configuration with Nix, and optionally manage system packages with Nix
    - Through the ISO
    - Over ssh with [nixos-anywhere](https://github.com/nix-community/nixos-anywhere), from a clone of this repository on another machine with the `nix` CLI (available on some Linux distributions, but also provided with the Nix package manager or NixOS)
      ```sh
      nix --extra-experimental-features 'nix-command flakes' run nixpkgs#nixos-anywhere -- \
        --flake .#anywhere \
        --generate-hardware-config nixos-generate-config ./machines/anywhere/hardware-configuration.nix \
        --kexec-extra-flags "--kexec-syscall" \
        --target-host root@<hostname>
      ```

- Clone the repository to your home directory. Without git (e.g. NixOS), get it with `nix-shell -p git`

  ```sh
  cd ~
  git clone <repo> dotfiles
  cd dotfiles
  ```

- Set the attributes in [nix/settings.nix](nix/settings.nix)

- Activate the configuration with one of the following. Home Manager is integrated with the system on NixOS and nix-darwin, and runs standalone anywhere else the Nix package manager is (e.g. Ubuntu, Arch Linux)

  ```sh
  # NixOS
  sudo nixos-rebuild switch --flake .
  # macOS, installing nix-darwin
  sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake .
  # home-manager standalone, installing Home Manager
  mkdir -p ~/.config/nix
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
  nix run --inputs-from . home-manager -- switch --flake .
  # then, start a new shell session (which will give the home-manager CLI)
  ```

  On a Linux distribution with a desktop, Nix's graphical apps need its GPU drivers linked in once (see [features/generic-linux.nix](features/generic-linux.nix)). The switch prints the command when they need linking, again after an update that changes them

  ```sh
  sudo "$(command -v non-nixos-gpu-setup)"
  ```

- Future rebuilds and activations can be done with [`nh`](https://github.com/nix-community/nh) (this will also rebuild an integrated Home Manager)

  ```sh
  nh os switch      # NixOS
  nh darwin switch  # macOS with nix-darwin
  nh home switch    # home-manager standalone
  ```

- (optional) Give the machine its [secrets](#secrets). Make its age key on it

  ```sh
  sudo mkdir -p /var/lib/sops-nix
  sudo "$(command -v age-keygen)" -o /var/lib/sops-nix/key.txt
  ```

  then, on a machine with the GPG key (this one, if it's the first), set the printed public key as its `secrets.ageKey` in [flake.nix](flake.nix), re-encrypt the secrets (and any `secrets/<hostname>.yaml`), and commit

  ```sh
  install -m 644 "$(nix build --no-link --print-out-paths .#sops-config)" .sops.yaml
  sops updatekeys secrets/fleet.yaml
  ```

  then pull on this machine and rebuild with `nh`

- (optional) Log in to the tailnet, tagged as one of the fleet's machines, so it can build on and download from the others (see [features/fleet-access](features/fleet-access/default.nix)). An exit node is `features.tailscale.exitNode`, not `--advertise-exit-node` by hand. The tag stays across reboots and rebuilds, so this is done once. A machine with secrets (NixOS, or a Mac that builds or serves a cache) has logged itself in already

  ```sh
  # NixOS, or a Mac that builds or serves a cache (with the open source tailscaled)
  sudo tailscale up --advertise-tags=tag:fleet
  # any other Mac (with the Tailscale app)
  /Applications/Tailscale.app/Contents/MacOS/Tailscale up --advertise-tags=tag:fleet
  ```

## Secrets

Secrets live in `secrets/`, encrypted with [sops](https://github.com/getsops/sops), and are decrypted on activation by [sops-nix](https://github.com/Mic92/sops-nix) (see [features/secrets.nix](features/secrets.nix)). `secrets/fleet.yaml` is for every machine and `secrets/<hostname>.yaml` is for that machine alone. The GPG key can open them all. A machine gets its own key during [Setup](#setup-macos--linux--wsl)

- Edit one (sops opens `$EDITOR`), on a machine with the GPG key

  ```sh
  sops secrets/fleet.yaml
  ```
