{
  tags = [ "workstation" ];

  packages = pkgs: pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.unstable.t3code ];

  # nixpkgs trails the macOS releases.
  system =
    { lib, systemKey, ... }:
    lib.optionalAttrs (systemKey == "darwin") {
      homebrew.casks = [ "t3-code" ];
    };
}
