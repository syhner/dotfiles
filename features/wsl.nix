# NixOS in WSL on Windows, with NixOS-WSL, which WSL's own kernel, boot and
# networking take the place of the usual NixOS ones for. The first install is
# from a tarball this configuration builds (see the README).
{
  config,
  lib,
  inputs,
  settings,
  ...
}:
{
  config = lib.mkIf config.features.wsl.enable {
    # It turns off the network manager nixos turns on.
    features.nixos.enable = true;

    system = {
      imports = [ inputs.nixos-wsl.nixosModules.default ];

      wsl.enable = true;
      # The user WSL logs in as.
      wsl.defaultUser = settings.user.name;

      # Windows manages the network.
      networking.networkmanager.enable = false;
    };
  };
}
