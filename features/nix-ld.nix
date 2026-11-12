# Runs binaries built for other Linux distributions, which tools download
# rather than get from Nix: Zed's Node and language servers, npm packages'
# prebuilt binaries, uv's Pythons. NixOS has no /lib64/ld-linux-*.so, so
# without this they fail with a misleading "No such file or directory".
# nix-ld puts a loader there that finds their libraries in
# programs.nix-ld.libraries: add one there if a binary is missing it.
#
# Only on NixOS: other distributions, and macOS, have a loader already.
{
  config,
  lib,
  machine,
  ...
}:
{
  config = lib.mkIf config.features.nix-ld.enable {
    system = lib.optionalAttrs machine.platform.isLinux {
      programs.nix-ld.enable = true;
    };
  };
}
