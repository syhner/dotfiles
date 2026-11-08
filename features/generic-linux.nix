# Home Manager on its own on a Linux distribution other than NixOS (Ubuntu,
# Arch and so on): the distribution's paths for menus, icons, terminfo and
# zsh functions, and the GPU drivers Nix's graphical apps need.
{ lib, machine, ... }:
{
  tags = [ "base" ];

  home = lib.optionalAttrs (machine.standalone && machine.platform.isLinux) {
    targets.genericLinux.enable = true;

    # Nix's graphical apps (Ghostty, Zed) only find drivers built by Nix, at
    # /run/opengl-driver. The first switch, and any switch that changes the
    # drivers, prints a command to run once with sudo that links them there.
    # Off without a desktop, where nothing would use them. An NVIDIA card
    # also needs gpu.nvidia, with the version the distribution runs.
    targets.genericLinux.gpu.enable = lib.elem "gui" machine.tags;
  };
}
