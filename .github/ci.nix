# What .github/workflows/ci.yml evaluates, builds and pushes to, so it
# lists none of it itself. Its plan job reads it with nix eval --json .#ci,
# and its build job runs once for each platform.
{
  lib,
  machines,
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
  # A builder's line in Nix's builders setting, at its tailnet address, as
  # the machines have it in nix.buildMachines.
  builderLine =
    builder:
    lib.concatStringsSep " " [
      (
        (import ../features/fleet-access/user.nix).storeUri builder.machine.address
        + lib.optionalString (builder.remoteProgram != null) "?remote-program=${builder.remoteProgram}"
      )
      builder.system
      "-"
      (toString builder.maxJobs)
      (toString builder.speedFactor)
      (lib.concatStringsSep "," builder.supportedFeatures)
    ];
  # The fleet's builders, for each platform, fastest first. CI builds on the
  # first it can reach over the tailnet.
  builders = lib.mapAttrs (_: lib.sort (a: b: a.speedFactor > b.speedFactor)) (
    lib.groupBy (builder: builder.system) (import ../features/fleet-builders/builders.nix lib machines)
  );
  # GitHub's runner for each platform it has one for. macOS has none: its
  # runners can sit in the queue until the job gives up.
  runners = {
    aarch64-linux = "ubuntu-24.04-arm";
    x86_64-linux = "ubuntu-latest";
  };
in
{
  cache = settings.cachix.name;

  credential = settings.tailscale.ciCredential;

  # what the build job reaches the builders with, as the machines do
  sshConfig = import ../features/ssh/tailnet.nix settings;

  # Without a runner, a platform builds only on its builders, from
  # ubuntu-latest, and is only evaluated when none answers.
  platforms = lib.mapAttrsToList (platform: group: {
    inherit platform;
    runner = runners.${platform} or "ubuntu-latest";
    local = runners ? ${platform};
    builders = map builderLine (builders.${platform} or [ ]);
    attrs = map (configuration: configuration.attr) group;
  }) (lib.groupBy (configuration: configuration.platform) configurations);

  # Empty rather than "()", which would match every package.
  unfree =
    let
      names = lib.unique (lib.concatMap (configuration: configuration.unfreePackageNames) configurations);
    in
    lib.optionalString (names != [ ]) "(${lib.concatMapStringsSep "|" lib.escapeRegex names})";
}
