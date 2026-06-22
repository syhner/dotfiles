# dotfiles

## Setup

- Install [Nix](https://nixos.org)

- (macOS) Install [nix-darwin](https://github.com/nix-darwin/nix-darwin)

  ```sh
  sudo nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --experimental-features 'nix-command flakes'
  ```

- (macOS) Install Xcode Command Line Tools (this will give git)

  ```sh
  xcode-select --install
  ```

- Clone the repository

  ```sh
  git clone <repo>
  ```

- Symlink dotfiles to the home directory

  ```sh
  cd dotfiles
  stow .
  ```

- Match machine hostname with [nix/flake.nix](nix/flake.nix) hostname

  ```sh
  sed -i '' "s/smacbook/$(scutil --get LocalHostName)/" flake.nix
  ```

- (macOS) Give Terminal Full Disk Access, then rebuild the system configuration

  ```sh
  sudo darwin-rebuild switch --flake ~/nix
  ```
