# Home Manager on its own on a Linux distribution other than NixOS (Ubuntu,
# Arch and so on): the distribution's paths for menus, icons, terminfo and
# zsh functions, and the GPU drivers Nix's graphical apps need.
{
  config,
  lib,
  machine,
  ...
}:
{
  options.features.generic-linux.gpu = lib.mkEnableOption "linking the GPU drivers Nix's graphical apps need";

  config = lib.mkIf config.features.generic-linux.enable {
    home = lib.optionalAttrs (machine.standalone && machine.platform.isLinux) {
      targets.genericLinux.enable = true;

      # Nix's graphical apps (Ghostty, Zed) only find drivers built by Nix, at
      # /run/opengl-driver. The first switch, and any switch that changes the
      # drivers, prints a command to run once with sudo that links them there.
      # On with the gui profile: without a desktop nothing would use
      # them. An NVIDIA card also needs gpu.nvidia, with the version the
      # distribution runs.
      targets.genericLinux.gpu.enable = config.features.generic-linux.gpu;
    };
  };
}
