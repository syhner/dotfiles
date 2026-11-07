# dotfiles

## Pre-requisites

### macOS
  
- Install [nix-darwin](https://github.com/nix-darwin/nix-darwin)

  ```sh
  sudo nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --experimental-features 'nix-command flakes'
  ```

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

- Clone the repository to your home directory (Home Manager links the features' config files to the clone, rather than copying them into the store, so edits apply without a rebuild). It can be cloned elsewhere under your home directory, but then `checkout` in [nix/settings.nix](nix/settings.nix) will need to be updated to its path.

  ```sh
  cd ~
  git clone <repo> dotfiles
  cd dotfiles
  ```

- Install one of:
  - [Nix (the package manager)](https://nixos.org/download/#nix-install-linux) if you just want to manage system packages with Nix
  - [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) on Windows, from a tarball of the `wsl` configuration built on a Linux machine with Nix (or download the release's `nixos.wsl` and switch to `wsl` afterwards)
    ```sh
    sudo nix run .#nixosConfigurations.wsl.config.system.build.tarballBuilder
    # then, on Windows, with the nixos.wsl it made
    wsl --install --from-file nixos.wsl
    ```
  - [NixOS (the Linux distribution)](https://nixos.org/download/#nixos-iso) if you want to manage your system configuration with Nix, and optionally manage system packages with Nix
    - Through the ISO
    - Over ssh with the [nix-anywhere](https://github.com/nix-community/nixos-anywhere)
 and the `nix` CLI (available on some Linux distributions, but also provided with the Nix package manager or NixOS)
      ```sh
      nix run nixpkgs#nixos-anywhere -- \
        --flake .#anywhere \
        --generate-hardware-config nixos-generate-config ./machines/anywhere/hardware-configuration.nix \
        --kexec-extra-flags "--kexec-syscall" \
        --target-host root@<hostname>
      ```

- Modify [nix/settings.nix](nix/settings.nix)

- (optional) Name the configuration in [flake.nix](flake.nix) after the machine's hostname, so rebuilds pick it without naming it (e.g. `--flake .#macbook`)

  ```sh
  sed -i '' "s/macbook/$(hostname)/" flake.nix
  ```

- Home Manager can either be integrated with the system (this is set up as the default if using NixOS or nix-darwin) or run standalone (which supports any platform where the nix package manager is available (e.g. Ubunutu, Arch Linux) by installing and running Home Manager

  ```sh
  mkdir -p ~/.config/nix
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
  nix run home-manager/release-26.05 -- switch --flake .
  # then, start a new shell session (which will give the home-manager CLI)
  ```

- Rebuild and activate the configuration with one of
  ```sh
  # NixOS
  sudo nixos-rebuild switch --flake .
  # macOS with nix-darwin
  sudo darwin-rebuild switch --flake .
  # home-manager standalone
  home-manager switch --flake .
  ```

- (optional) Log in to the tailnet, tagged as one of the fleet's machines, so it can build on and download from the others (see [features/fleet-access.nix](features/fleet-access.nix)). Add `--advertise-exit-node` on an exit node. The tag stays across reboots and rebuilds, so this is done once

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

## External requirements

### Required

- `CACHIX_AUTH_TOKEN` repository secret, for CI to push what it builds to the Cachix cache
- `FLAKE_UPDATE_TOKEN` repository secret, for the weekly `flake.lock` update pull request to start CI

### Optional

- A `tag:fleet` tag in the tailnet policy, for the machines to log in with (see Setup), and a rule letting `tag:fleet` machines SSH in to each other as `fleet-servant`, for remote builds and the shared caches
- MagicDNS on in the tailnet, at the domain `tailnet` names in [nix/settings.nix](nix/settings.nix): the machines reach each other at their names under it
