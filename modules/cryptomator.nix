{
  tags = [ "workstation" ];

  packages = pkgs: pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.unstable.cryptomator ];

  # nixpkgs only builds Cryptomator for Linux.
  system =
    { lib, systemKey, ... }:
    lib.optionalAttrs (systemKey == "darwin") {
      homebrew.casks = [ "cryptomator" ];
    };
}
