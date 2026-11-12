# An NVIDIA graphics card, with NVIDIA's driver.
{ config, lib, ... }:
{
  config = lib.mkIf config.features.nvidia.enable {
    unfree = [
      "nvidia-x11"
      "nvidia-settings"
    ];

    system = {
      hardware.graphics.enable = true;
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        # Needed by Wayland, which Plasma and GNOME use.
        modesetting.enable = true;

        # NVIDIA's open kernel modules, which it recommends for RTX 20 series
        # (Turing) cards and newer. A GTX 16 series card or older needs false.
        open = true;
      };
    };
  };
}
