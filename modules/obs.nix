{
  tags = [ "workstation" ];

  packages = pkgs: pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.obs-studio ];

  # nixpkgs only builds OBS for Linux.
  system =
    { lib, systemKey, ... }:
    lib.optionalAttrs (systemKey == "darwin") {
      homebrew.casks = [ "obs" ];
    };
}
