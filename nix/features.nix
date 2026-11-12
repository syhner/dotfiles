# Every feature and profile, each switched on with its enable option.
{ lib, ... }:
let
  files = builtins.attrNames (removeAttrs (builtins.readDir ../features) [ "profiles" ]);
  profiles = builtins.attrNames (builtins.readDir ../features/profiles);

  # A module, or a list of them.
  modules = lib.types.coercedTo lib.types.raw lib.toList (lib.types.listOf lib.types.raw);
in
{
  # reversed, so lists like packages merge in the features' alphabetical order
  imports =
    lib.reverseList (map (file: ../features/${file}) files)
    ++ map (file: ../features/profiles/${file}) profiles;

  options = {
    features =
      lib.genAttrs (map (lib.removeSuffix ".nix") files) (name: {
        enable = lib.mkEnableOption "the ${name} feature";
      })
      // {
        profiles = lib.genAttrs (map (lib.removeSuffix ".nix") profiles) (name: {
          enable = lib.mkEnableOption "the ${name} profile";
        });
      };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.raw;
      default = [ ];
      description = "Packages to install, on the system, or in a standalone home.";
    };

    home = lib.mkOption {
      type = modules;
      default = [ ];
      description = "Home Manager modules.";
    };

    system = lib.mkOption {
      type = modules;
      default = [ ];
      description = "NixOS or nix-darwin modules. A standalone home has none.";
    };

    unfree = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Names of the unfree packages to allow.";
    };
  };
}
