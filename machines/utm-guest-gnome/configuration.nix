{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # The NixOS release this machine was first installed with, which some
  # state-keeping defaults follow. Don't change it when upgrading NixOS.
  system.stateVersion = "26.05";
}
