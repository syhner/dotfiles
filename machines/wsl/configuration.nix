# NixOS in WSL on Windows. WSL provides the kernel, boot and disks, so there's
# no hardware configuration (see features/wsl.nix).
{
  # The NixOS release this machine was first installed with, which some
  # state-keeping defaults follow. Don't change it when upgrading NixOS.
  system.stateVersion = "26.05";
}
