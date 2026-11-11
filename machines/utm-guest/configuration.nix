{ pkgs, ... }:
{
  # TEMPORARY: a package no cache has, to see CI build it on the macbook's VM.
  environment.systemPackages = [
    (pkgs.stdenvNoCC.mkDerivation {
      pname = "linux-builder-relay-test";
      version = "1";
      dontUnpack = true;
      installPhase = "mkdir $out; uname -a >$out/uname; nproc >$out/nproc";
    })
  ];

  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # The NixOS release this machine was first installed with, which some
  # state-keeping defaults follow. Don't change it when upgrading NixOS.
  system.stateVersion = "26.05";
}
