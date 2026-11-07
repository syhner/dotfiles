# The desktop PC: a Ryzen 9 with an NVIDIA graphics card.
{ inputs, ... }:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
    ./disk-config.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # The NixOS release this machine was first installed with, which some
  # state-keeping defaults follow. Don't change it when upgrading NixOS.
  system.stateVersion = "26.05";
}
