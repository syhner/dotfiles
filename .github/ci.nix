# What .github/workflows/ci.yml evaluates, builds and pushes to, so it
# lists none of it itself. Its plan job reads it with nix eval --json .#ci.
{
  lib,
  self,
  settings,
}:
let
  entries =
    prefix: build:
    lib.mapAttrsToList (
      name: configuration: {
        attr = "${prefix}.${name}.${build}";
        platform = configuration.machine.platform.system;
        unfreePackageNames = configuration.machine.unfreePackageNames;
      }
    );

  configurations =
    entries "darwinConfigurations" "system" self.darwinConfigurations
    ++ entries "nixosConfigurations" "config.system.build.toplevel" self.nixosConfigurations
    ++ lib.concatMap (
      platform:
      entries "legacyPackages.${platform}.homeConfigurations" "activationPackage"
        self.legacyPackages.${platform}.homeConfigurations
    ) (builtins.attrNames self.legacyPackages);
in
{
  cache = settings.cache.name;

  configurations = map (configuration: {
    inherit (configuration) attr platform;
  }) configurations;

  unfree = "(${
    lib.concatMapStringsSep "|" lib.escapeRegex (
      lib.unique (lib.concatMap (configuration: configuration.unfreePackageNames) configurations)
    )
  })";
}
