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

- Clone the repository to your home directory (this is only necessary for home-manager to find files referenced by absolute path when using `mkOutOfStoreSymlink`). It can be cloned elsewhere, but then `repositoryPath` in [flake.nix](nix/flake.nix) will need to be updated to the path of the cloned repository.

  ```sh
  cd ~
  git clone <repo> dotfiles
  cd dotfiles
  ```

- Install one of:
  - [Nix (the package manager)](https://nixos.org/download/#nix-install-linux) if you just want to manage system packages with Nix
  - [NixOS (the Linux distribution)](https://nixos.org/download/#nixos-iso) if you want to manage your system configuration with Nix, and optionally manage system packages with Nix
    - Through the ISO
    - Over ssh with the [nix-anywhere](https://github.com/nix-community/nixos-anywhere)
 and the `nix` CLI (available on some Linux distributions, but also provided with the Nix package manager or NixOS)
      ```sh
      nix run nixpkgs#nixos-anywhere -- \
        --flake ./nix#anywhere \
        --generate-hardware-config nixos-generate-config ./nix/hosts/anywhere/hardware-configuration.nix
        --kexec-extra-flags "--kexec-syscall" \
        --target-host root@<hostname>
      ```

- Modify the username in [nix/flake.nix](nix/flake.nix)

  ```sh
  sed -i '' "s/siraj/$(whoami)/" nix/flake.nix
  ```

- (optional) Match your hostname to the desired flake configuration hostname in [nix/flake.nix](nix/flake.nix) (e.g. `macbook`) to avoid having to specify the hostname on every rebuild (e.g. `--flake ./nix#macbook`)

  ```sh
  sed -i '' "s/macbook/$(hostname)/" nix/flake.nix
  ```

- If using home-manager standalone (which supports any platform where the nix package manager is available) then install and run home-manager. (this is not necessary if using nix-darwin or NixOS, as home-manager is set up as a module)

  ```sh
    nix run home-manager/release-26.05 switch -- --flake ./nix
    # then, start a new shell session (which will also give the home-manager CLI)
  ```

- Rebuild the system configuration with either
  - the preconfigured alias `nixswitch` (if symlinked dotfiles to the home directory) (this is set up to also rebuild the home configuration, unless home-manager standalone was set up)
  - or one of
    ```sh
    # NixOS
    sudo nixos-rebuild switch --flake ./nix
    # macOS
    sudo darwin-rebuild switch --flake ./nix
    # home-manager standalone
    home-manager switch --flake ./nix
    ```
