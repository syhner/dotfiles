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
  # The fleet's builders (see features/fleet-builders.nix), for each
  # platform, fastest first. CI builds on the first it can reach over the
  # tailnet.
  builders = lib.mapAttrs (_: lib.sort (a: b: a.speedFactor > b.speedFactor)) (
    lib.groupBy (builder: builder.system) (
      map
        (machine: {
          inherit (machine) hostname;
          inherit (machine.builder) maxJobs speedFactor;
          system = machine.platform.system;
          # As fleet-builders.nix gives the others.
          supportedFeatures = [
            "benchmark"
            "big-parallel"
          ]
          ++ lib.optionals machine.platform.isLinux [
            "nixos-test"
            "kvm"
          ];
        })
        (
          builtins.filter (machine: machine.builder != null) (
            map (configuration: configuration.machine) (
              builtins.attrValues (self.nixosConfigurations // self.darwinConfigurations)
            )
          )
        )
    )
  );
in
{
  cache = settings.cache.name;

  inherit builders;

  credential = settings.ciCredential;

  configurations = map (configuration: {
    inherit (configuration) attr platform;
  }) configurations;

  # Empty rather than "()", which would match every package.
  unfree =
    let
      names = lib.unique (lib.concatMap (configuration: configuration.unfreePackageNames) configurations);
    in
    lib.optionalString (names != [ ]) "(${lib.concatMapStringsSep "|" lib.escapeRegex names})";
}
