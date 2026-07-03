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

## Setup

- Install [Nix](https://nixos.org)

- Clone the repository

  ```sh
  git clone <repo>
  cd dotfiles
  ```

- (optional) Symlink dotfiles to the home directory

  ```sh
  stow .
  ```

- Modify the username in [nix/lib/mksystem.nix](nix/lib/mksystem.nix)

  ```sh
  sed -i '' "s/siraj/$(whoami)/" nix/lib/mksystem.nix
  ```

- (optional) Match your hostname to the desired flake configuration hostname (e.g. `macbook`) in [nix/flake.nix](nix/flake.nix to avoid having to specify the hostname on every rebuild (e.g. `--flake ./nix#macbook`)

  ```sh
  sed -i '' "s/macbook/$(hostname)/" nix/flake.nix
  ```


- If using home-manager standalone (which supports any platform where the nix package manager is available) then install and run home-manager. (this is not necessary if using nix-darwin or NixOS, as home-manager is set up as a module)

  ```sh
    nix run home-manager/release-26.05 switch -- --flake ./nix
    # then, start a new shell session
  ```

- Rebuild the system/home configuration with either
  - the preconfigured alias `nixswitch` (if symlinked dotfiles to the home directory)
  - or one of
    ```sh
    # NixOS
    sudo nixos-rebuild switch --flake ./nix
    # macOS
    sudo darwin-rebuild switch --flake ./nix
    # home-manager standalone
    home-manager switch --flake ./nix
    ```
