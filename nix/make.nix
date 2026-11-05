{ inputs }:
{
  platform, # for example "aarch64-darwin"
  hostname ? null, # none for a standalone home
  tags,
  standalone ? false, # whether Home Manager runs on its own rather than in a system
  # Whether the configuration may use unfree packages: the ones its features
  # name, and no others.
  allowUnfree ? false,
  # For a machine that builds for the others (see features/remote-builds.nix):
  # { maxJobs, speedFactor }.
  builder ? null,
  # For a machine that serves its store as a binary cache to the others (see
  # features/harmonia.nix): { publicKey, priority }.
  substituter ? null,
}@args:

assert standalone || hostname != null || throw "a system needs a hostname";

let
  inherit (inputs.nixpkgs-nixos) lib;
  settings = import ./settings.nix;

  # The platform, expanded from the string into its details, such as
  # platform.isDarwin, platform.isx86_64 and platform.system (the string
  # itself). Everything that differs by platform checks this.
  platform = lib.systems.elaborate args.platform;

  nixpkgsArgs = {
    system = platform.system;
    # Only the unfree packages the included features name. Using any other
    # fails evaluation with the name to add to the feature's unfree list.
    config.allowUnfreePredicate = package: allowUnfree && builtins.elem (lib.getName package) unfree;
  };

  # The nixpkgs release for the platform.
  pkgs = import (
    if platform.isDarwin then inputs.nixpkgs-darwin else inputs.nixpkgs-nixos
  ) nixpkgsArgs;
  unstable = import inputs.nixpkgs-unstable nixpkgsArgs;

  # What every feature takes. These are plain values rather than module
  # arguments, so a feature can branch on any of them, pkgs included, without
  # infinite recursion. Only config still has to come from inside the system
  # or home part.
  homeDirectory =
    if platform.isDarwin then "/Users/${settings.username}" else "/home/${settings.username}";
  repositoryPath = "${homeDirectory}/dotfiles";

  # The file at a path in this repository, as a link to the same file in the
  # checkout rather than a copy in the store, so editing it takes effect
  # without a rebuild.
  link =
    path:
    let
      checkoutPath = repositoryPath + lib.removePrefix "." (lib.path.removePrefix ../. path);
    in
    # Named the way Home Manager's mkOutOfStoreSymlink names its links.
    pkgs.runCommandLocal (inputs.home-manager.lib.hm.strings.storeFileName (
      baseNameOf path
    )) { } "ln -s ${lib.escapeShellArg checkoutPath} $out";

  featureArgs = {
    inherit
      builder
      homeDirectory
      hostname
      inputs
      lib
      link
      pkgs
      platform
      repositoryPath
      settings
      standalone
      substituter
      # The configuration's tags, so a feature can depend on another tag.
      tags
      unstable
      ;
  };

  # Every feature (each file or directory in features/), called with what it
  # takes. A feature has tags and up to three parts: packages, and the home
  # and system parts, which are Home Manager and NixOS/nix-darwin modules. It
  # also names the unfree packages it uses, if any, in unfree.
  features = map (name: import ../features/${name} featureArgs) (
    builtins.attrNames (builtins.readDir ../features)
  );

  # One part of some features, as a single list. For example,
  # partOf "packages" included gives every package they install.
  partOf = part: builtins.concatMap (feature: lib.toList (feature.${part} or [ ]));

  # The features whose tags this configuration shares.
  included = builtins.filter (feature: lib.intersectLists tags feature.tags != [ ]) features;

  # The names of the unfree packages the configuration may use. A feature's
  # tags and unfree list mustn't depend on an unfree package, or this would
  # depend on itself.
  unfree = partOf "unfree" included;

  # The packages to install, without any that don't run on this platform.
  packages = lib.pipe included [
    (partOf "packages")
    (builtins.filter (lib.meta.availableOn platform))
  ];

  # The system installs the packages and runs Home Manager.
  systemModules = [
    ../hosts/${hostname}/configuration.nix
    {
      nixpkgs.pkgs = pkgs;
      environment.systemPackages = packages;
    }
    {
      imports = [
        inputs.home-manager.${if platform.isDarwin then "darwinModules" else "nixosModules"}.home-manager
      ];

      users.users.${settings.username}.home = homeDirectory;
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${settings.username}.imports = homeModules;
    }
  ]
  ++ partOf "system" included;

  # The home. With no system around, it installs the packages itself.
  homeModules =
    lib.optional standalone { home.packages = packages; }
    ++ [
      {
        home.username = settings.username;
        home.homeDirectory = homeDirectory;
        home.stateVersion = "26.05";
        programs.home-manager.enable = true;
      }
    ]
    ++ partOf "home" included;
in
assert
  allowUnfree
  || unfree == [ ]
  || throw "${
    if standalone then "the standalone home" else hostname
  } includes features with unfree packages (${toString unfree}), so it needs allowUnfree = true";
(
  if standalone then
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = homeModules;
    }
  else
    (if platform.isDarwin then inputs.nix-darwin.lib.darwinSystem else lib.nixosSystem) {
      # For the host's own configuration.nix, which isn't a module.
      specialArgs = { inherit inputs hostname settings; };
      modules = systemModules;
    }
)
// {
  # What the arguments say about the configuration, for what reads all of
  # them: the ci output in flake.nix, features/remote-builds.nix and
  # features/harmonia.nix.
  dotfiles = {
    platform = platform.system;
    inherit builder substituter unfree;
  };
}
