# A machine to install NixOS on over SSH, with nixos-anywhere (see the
# README). It has no tags: it's the bare system, plus SSH in as root.
{
  inputs,
  lib,
  modulesPath,
  pkgs,
  settings,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.disko.nixosModules.disko
    ./disk-config.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  services.openssh.enable = true;
  # Only with a key, as on the tagged machines (see features/ssh).
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "prohibit-password";
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  users.users.root.openssh.authorizedKeys.keys = [ settings.sshPublicKey ];

  # The NixOS release this machine was first installed with, which some
  # state-keeping defaults follow. Don't change it when upgrading NixOS.
  system.stateVersion = "26.05";
}
