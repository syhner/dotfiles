# NixOS in WSL on Windows, with NixOS-WSL, which WSL's own kernel, boot and
# networking take the place of the usual NixOS ones for. The first install is
# from a tarball this configuration builds (see the README).
{ inputs, settings, ... }:
{
  tags = [ "wsl" ];

  system = {
    imports = [ inputs.nixos-wsl.nixosModules.default ];

    wsl.enable = true;
    # The user WSL logs in as.
    wsl.defaultUser = settings.username;
  };
}
