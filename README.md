# dotfiles

Setting up a machine with its configuration in [flake.nix](flake.nix). To add one, see [Adding a machine](#9-adding-a-machine).

## 1. Pre-requisites

- macOS

  - Install Xcode Command Line Tools (this will give git)

    ```sh
    xcode-select --install
    ```

  - Install Rosetta

    ```sh
    softwareupdate --install-rosetta --agree-to-license
    ```

  - Give Terminal Full Disk Access

  - Sign in to the App Store, for the `masApps` in [features/darwin/homebrew.nix](features/darwin/homebrew.nix)

- A Linux distribution other than NixOS: curl, for the Nix installer (e.g. on Ubuntu)

  ```sh
  sudo apt install curl
  ```

## 2. Install Nix

- Install one of:
  - [Nix (the package manager)](https://nixos.org/download/) on macOS, or on a Linux distribution if you just want to manage system packages with Nix. Then open a new shell
  - [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) on Windows, from a tarball of the `wsl` configuration built on a Linux machine with Nix, in a clone of this repository (or install the release's `nixos.wsl`, whose user is `nixos`, and switch it to `wsl` as in [Change the username](https://nix-community.github.io/NixOS-WSL/how-to/change-username.html))
    ```sh
    sudo nix --extra-experimental-features 'nix-command flakes' run .#nixosConfigurations.wsl.config.system.build.tarballBuilder
    # then, on Windows, with the nixos.wsl it made
    wsl --install --from-file nixos.wsl
    ```
  - [NixOS (the Linux distribution)](https://nixos.org/download/#nixos-iso) if you want to manage your system configuration with Nix, and optionally manage system packages with Nix
    - Through the ISO. For a machine without a `disk-config.nix`, install as usual, with the user from `user.name` in [nix/settings.nix](nix/settings.nix). For one with a `disk-config.nix`, partition with [disko](https://github.com/nix-community/disko) and install from a clone in the installer (disko erases the disk: check it with `lsblk` first), then reboot
      ```sh
      nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#git -c git clone <repo> /tmp/dotfiles
      cd /tmp/dotfiles
      sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko/latest -- --mode destroy,format,mount --flake .#<hostname>
      sudo nixos-generate-config --no-filesystems --root /mnt --show-hardware-config > machines/<hostname>/hardware-configuration.nix
      sudo nixos-install --flake .#<hostname> --no-root-passwd
      # the user's password, until the machine has its secrets (see 5)
      sudo nixos-enter --root /mnt -c 'passwd <user>'
      # keep the hardware configuration, as /tmp is gone after the reboot
      sudo install -D -m 644 machines/<hostname>/hardware-configuration.nix /mnt/etc/nixos/hardware-configuration.nix
      ```
    - Over ssh with [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)

## 3. Clone

- Clone the repository to your home directory. Without git (e.g. NixOS)

  ```sh
  nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#git -c git clone <repo> ~/dotfiles
  cd ~/dotfiles
  ```

## 4. One-time setup

- The tailnet policy in [features/fleet-access](features/fleet-access/default.nix), for remote builds and the shared caches, with its `tag:ci` parts for CI to build on them too

## 5. Settings and secrets

- Set the attributes in [nix/settings.nix](nix/settings.nix)

- (NixOS installed through the ISO) Its disks are new, so take its hardware configuration

  ```sh
  cp /etc/nixos/hardware-configuration.nix machines/<hostname>/
  ```

- (optional, NixOS or macOS, not the first machine) Give the machine its secrets, from `secrets/`, encrypted with [sops](https://github.com/getsops/sops) and decrypted on activation by [sops-nix](https://github.com/Mic92/sops-nix) (see [features/secrets.nix](features/secrets.nix)). `secrets/fleet.yaml` is for every machine and `secrets/<hostname>.yaml` is for that machine alone. Make its age key on it

  ```sh
  sudo mkdir -p /var/lib/sops-nix
  nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#age -c sh -c 'sudo "$(command -v age-keygen)" -o /var/lib/sops-nix/key.txt'
  ```

  then, on a machine with the GPG key, set the printed public key as its `secrets.ageKey` in [flake.nix](flake.nix), re-encrypt the secrets, and commit and push

  ```sh
  install -m 644 "$(nix build --no-link --print-out-paths .#sops-config)" .sops.yaml
  sops updatekeys secrets/fleet.yaml
  sops updatekeys secrets/<hostname>.yaml  # if there is one
  ```

  then pull on this machine

- (NixOS with secrets) `secrets/fleet.yaml` has the user's `password`, as a hash, which it sets on every switch. Set it once, on a machine with the GPG key

  ```sh
  sops set secrets/fleet.yaml '["password"]' "\"$(nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#mkpasswd -c mkpasswd)\""
  ```

## 6. Activate

- (NixOS or macOS) Set the hostname to its configuration's name in [flake.nix](flake.nix), so the switch finds it. The switch then sets it for good

  ```sh
  sudo hostname <hostname>                    # NixOS
  sudo scutil --set LocalHostName <hostname>  # macOS
  ```

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
  ```

  On a Linux distribution with a desktop, Nix's graphical apps need its GPU drivers linked in once (see [features/generic-linux.nix](features/generic-linux.nix)). The switch prints the command when they need linking, again after an update that changes them

  ```sh
  sudo "$(command -v non-nixos-gpu-setup)"
  ```

- (home-manager standalone) Make zsh the login shell, then log out and back in (which will give the home-manager CLI)

  ```sh
  command -v zsh | sudo tee -a /etc/shells
  chsh -s "$(command -v zsh)"
  ```

## 7. After activating

- Future rebuilds and activations can be done with [`nh`](https://github.com/nix-community/nh) (this will also rebuild an integrated Home Manager)

  ```sh
  nh os switch      # NixOS
  nh darwin switch  # macOS with nix-darwin
  nh home switch    # home-manager standalone
  ```

- (optional) Import the GPG subkeys, for signing commits, the SSH key, and the secrets

  ```sh
  gpg --import <subkeys>.asc
  ```

- (optional, NixOS or macOS, the first machine) Give it its secrets as in [5](#5-settings-and-secrets), now that it has the GPG key, on itself, and rebuild with `nh`

- (optional) Log in to the tailnet, tagged as one of the fleet's machines, so it can build on and download from the others (see [features/fleet-access](features/fleet-access/default.nix)). An exit node is `features.tailscale.exitNode`, not `--advertise-exit-node` by hand. One out of the fleet, with neither `fleet-builders` nor `fleet-substituters` (the vps), is logged in without the tag, which lets a machine log in to the builders and caches as a user Nix trusts. The tag stays across reboots and rebuilds, so this is done once. The first `up` drops what `tailscale set` applied on boot (Tailscale SSH, an exit node), so apply it again

  ```sh
  # NixOS
  sudo tailscale up --advertise-tags=tag:fleet
  sudo systemctl restart tailscaled-set
  # a Mac that builds or serves a cache (with the open source tailscaled)
  sudo tailscale up --advertise-tags=tag:fleet
  sudo launchctl kickstart -k system/org.nixos.tailscale-set
  # any other Mac (with the Tailscale app)
  /Applications/Tailscale.app/Contents/MacOS/Tailscale up --advertise-tags=tag:fleet
  ```

## 8. GitHub (once)

- `CACHIX_AUTH_TOKEN` repository secret, for CI to push what it builds to the Cachix cache (without it, CI only downloads from it)
- `FLAKE_UPDATE_TOKEN` repository secret, for the weekly `flake.lock` update pull request, and for it to start CI

## 9. Adding a machine

Before setting it up as above, on a machine with the GPG key. `git add` new files, or the flake won't see them

- Its configuration in [flake.nix](flake.nix), named by its hostname, and its `machines/<hostname>/configuration.nix`

- (NixOS) Its `machines/<hostname>/hardware-configuration.nix`
  - Through the ISO without disko: as in [5](#5-settings-and-secrets)
  - Through the ISO with disko: a `disk-config.nix` (e.g. [machines/desktop/disk-config.nix](machines/desktop/disk-config.nix)), and an empty `{ }` to `git add`, which the install in [2](#2-install-nix) fills in and [5](#5-settings-and-secrets) brings back

- (a cache, with `fleet-substituters.priority`) The key it signs with: its public half as its `fleet-substituters.publicKey`, and the secret as `harmonia` in `secrets/<hostname>.yaml`

  ```sh
  nix key generate-secret --key-name <hostname>-1 > key
  nix key convert-secret-to-public < key
  sops secrets/<hostname>.yaml
  rm key
  ```

## 10. macOS settings set by hand

Not in nix yet, grouped by how nix could set them.

### Nix could set

- Menu bar: Apple's icons, with `system.defaults.controlcenter` and `menuExtraClock`
- Berkeley Mono: `fonts.packages`, from a private flake input

### Nix could set, once the key is found

Diff `defaults read` before and after changing it, then set it with `CustomUserPreferences`.

- Passwords: delete verification codes after use
- Spotlight: clipboard history for 7 days
- Podcasts: auto download off
- Storage: Apple TV deletes watched downloads
- Messages: read receipts off
- Helium: ask where to save each file (the `PromptForDownloadLocation` policy)

### Only as a command run at activation

- Default browser: Helium, with `defaultbrowser` (asks to confirm)
- Keyboard shortcuts: Ctrl+arrows off for Mission Control, App windows, and moving a space left or right, with `defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add` for 32, 33, 79 and 81 (`CustomUserPreferences` would replace every shortcut)
- Wallpaper: black, with `desktoppr` or `osascript`
- Login items: MonitorControl and LookAway (they add themselves)

### Nix can't set

- iCloud: Photos sync off; Obsidian's folder kept downloaded
- Touch ID fingers
- Privacy & Security: Accessibility for MonitorControl, App Management for Zed, and the network extensions apps ask for
- Lock Screen: require password immediately (`sysadminctl -screenLock immediate -password -`)
- Keyboard: brightness, backlight off after 5 seconds
- Messages: share Focus status
- Menu bar: other apps' icons
- Helium: cycle tabs by recent use, new tab next to current, centered minimal address bar, no rounded frames
