# dotfiles

## Setup

- Install [Nix](https://nixos.org) and [nix-darwin](https://github.com/nix-darwin/nix-darwin)

```sh
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh
sudo nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --experimental-features 'nix-command flakes'
```

- Install Xcode Command Line Tools (this will give git)

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
sudo scutil --set <hostname>
```

- Rebuild the system configuration

```sh
sudo darwin-rebuild switch --flake ~/nix
```
