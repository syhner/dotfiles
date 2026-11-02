{
  tags = [ "workstation" ];
  # On Linux, discord wraps discord-unwrapped.
  unfree = [
    "discord"
    "discord-unwrapped"
  ];

  packages = pkgs: pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.unstable.discord ];

  # The nixpkgs build gets stuck installing its helper on macOS.
  system =
    { lib, systemKey, ... }:
    lib.optionalAttrs (systemKey == "darwin") {
      homebrew.casks = [ "discord" ];
    };
}
