# dotfiles

## External setup

All optional, done once, before any machine. Each turns on what it's for.

### Tailscale

- The tailnet policy in [features/fleet-access](features/fleet-access/default.nix), for remote builds and the shared caches, with its `tag:ci` parts for CI to build on them too
- MagicDNS on, at the domain `tailnet` names in [nix/settings.nix](nix/settings.nix), for the same: the machines reach each other at their names under it
- An OAuth client (Settings → Trust credentials) with the `auth_keys` scope (write) and the `tag:fleet` tag, whose secret is `tailscale` in `secrets/fleet.yaml` (see [Secrets](#secrets)), for a machine with secrets to log itself in
- A trust credential (Settings → Trust credentials), OpenID Connect, for GitHub (issuer `https://token.actions.githubusercontent.com`), trusting this repository's workflows (subject `repo:syhner/dotfiles:*`, and claims `repository_id` and `repository_owner_id`), with the `auth_keys` scope (write) and the `tag:ci` tag, whose client ID and audience are `ciCredential` in [nix/settings.nix](nix/settings.nix), for CI to build on the fleet's builders over the tailnet (see the build job in [.github/workflows/ci.yml](.github/workflows/ci.yml)), without which it builds on GitHub's runners and only evaluates the macOS configurations

### GitHub

- `CACHIX_AUTH_TOKEN` repository secret, for CI to push what it builds to the Cachix cache (without it, CI only downloads from it)
- `FLAKE_UPDATE_TOKEN` repository secret, for the weekly `flake.lock` update pull request, and for it to start CI

## Secrets

Secrets live in `secrets/`, encrypted with [sops](https://github.com/getsops/sops), and are decrypted on activation by [sops-nix](https://github.com/Mic92/sops-nix) (see [features/secrets.nix](features/secrets.nix)). `secrets/fleet.yaml` is for every machine and `secrets/<hostname>.yaml` is for that machine alone. The GPG key (`secretsKeys` in [nix/settings.nix](nix/settings.nix)) can open them all. A machine gets its own key in [Setup](#setup-macos--linux--wsl)

- Before any machine gets its secrets, set `password` in `secrets/fleet.yaml` to a hash from `mkpasswd`, and `tailscale` to the OAuth client's secret (see [External setup](#tailscale))

- Edit one (sops opens `$EDITOR`)

  ```sh
  sops secrets/fleet.yaml
  ```

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
  - [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) on Windows, from a tarball of the `wsl` configuration built from a clone of this repository on a Linux machine with Nix (or download the release's `nixos.wsl` and switch to `wsl` afterwards)
    ```sh
    sudo nix run .#nixosConfigurations.wsl.config.system.build.tarballBuilder
    # then, on Windows, with the nixos.wsl it made
    wsl --install --from-file nixos.wsl
    ```
  - [NixOS (the Linux distribution)](https://nixos.org/download/#nixos-iso) if you want to manage your system configuration with Nix, and optionally manage system packages with Nix
    - Through the ISO
    - Over ssh with [nixos-anywhere](https://github.com/nix-community/nixos-anywhere), from a clone of this repository on another machine with the `nix` CLI (available on some Linux distributions, but also provided with the Nix package manager or NixOS)
      ```sh
      nix run nixpkgs#nixos-anywhere -- \
        --flake .#anywhere \
        --generate-hardware-config nixos-generate-config ./machines/anywhere/hardware-configuration.nix \
        --kexec-extra-flags "--kexec-syscall" \
        --target-host root@<hostname>
      ```

- Clone the repository to your home directory (Home Manager links the features' config files to the clone, rather than copying them into the store, so edits apply without a rebuild). It can be cloned elsewhere under your home directory, but then `checkout` in [nix/settings.nix](nix/settings.nix) will need to be updated to its path. On NixOS without git, get it with `nix-shell -p git`

  ```sh
  cd ~
  git clone <repo> dotfiles
  cd dotfiles
  ```

- Modify [nix/settings.nix](nix/settings.nix)

- (optional) Name the configuration in [flake.nix](flake.nix) after the machine's hostname, so rebuilds pick it without naming it (e.g. `--flake .#macbook`)

  ```sh
  sed -i '' "s/macbook/$(hostname)/" flake.nix
  ```

- (optional) Give the machine its secrets (see [Secrets](#secrets)), before activating it: on NixOS, the password is only set by the activation that creates the user. Make its age key on the machine

  ```sh
  sudo mkdir -p /var/lib/sops-nix
  sudo nix shell nixpkgs#age -c age-keygen -o /var/lib/sops-nix/key.txt
  ```

  then add the public key it prints to the machine in [flake.nix](flake.nix) as `secrets.ageKey` and, on a machine with the GPG key, remake `.sops.yaml` and re-encrypt the secrets for it. Commit, and pull on the new machine

  ```sh
  install -m 644 "$(nix build --no-link --print-out-paths .#sops-config)" .sops.yaml
  nix shell nixpkgs#sops -c sops updatekeys secrets/fleet.yaml secrets/<hostname>.yaml
  ```

- Activate the configuration with one of the following. Home Manager is integrated with the system on NixOS and nix-darwin, and runs standalone anywhere else the Nix package manager is (e.g. Ubuntu, Arch Linux)

  ```sh
  # NixOS
  sudo nixos-rebuild switch --flake .
  # macOS, installing nix-darwin
  sudo nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake . --experimental-features 'nix-command flakes'
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

- (optional) Log in to the tailnet, tagged as one of the fleet's machines, so it can build on and download from the others (see [features/fleet-access](features/fleet-access/default.nix)). Add `--advertise-exit-node` on an exit node. The tag stays across reboots and rebuilds, so this is done once. A machine with secrets (NixOS, or a Mac that builds or serves a cache) has logged itself in already

  ```sh
  # NixOS, or a Mac that builds or serves a cache (with the open source tailscaled)
  sudo tailscale up --advertise-tags=tag:fleet
  # any other Mac (with the Tailscale app)
  /Applications/Tailscale.app/Contents/MacOS/Tailscale up --advertise-tags=tag:fleet
  ```

- Future rebuilds and activations can be done with [`nh`](https://github.com/nix-community/nh) (this will also rebuild an integrated Home Manager)

  ```sh
  nh os switch      # NixOS
  nh darwin switch  # macOS with nix-darwin
  nh home switch    # home-manager standalone
  ```
