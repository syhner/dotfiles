{ inputs }:
{
  platform, # for example "aarch64-darwin"
  hostname ? null, # none for a standalone home
  tags,
  standalone ? false, # whether Home Manager runs on its own rather than in a system
  allowUnfree ? false,
}@args:

assert standalone || hostname != null || throw "a system needs a hostname";

let
  inherit (inputs.nixpkgs-nixos) lib;
  settings = import ./settings.nix;

  # The platform, expanded from the string into its details, such as
  # platform.isDarwin, platform.isx86_64 and platform.system (the string
  # itself). Everything that differs by platform checks this.
  platform = lib.systems.elaborate args.platform;

  # The nixpkgs release for the platform.
  nixpkgs = if platform.isDarwin then inputs.nixpkgs-darwin else inputs.nixpkgs-nixos;

  nixpkgsConfig = { inherit allowUnfree; };

  # nixpkgs-unstable as pkgs.unstable.
  overlay = final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (platform) system;
      config = nixpkgsConfig;
    };
  };

  pkgs = import nixpkgs {
    inherit (platform) system;
    config = nixpkgsConfig;
    overlays = [ overlay ];
  };

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
      # The configuration's tags, so a feature can depend on another tag.
      tags
      ;
  };

  # Every feature (each file or directory in features/), called with what it
  # takes. A feature has tags and up to three parts: packages, and the home
  # and system parts, which are Home Manager and NixOS/nix-darwin modules.
  features = map (name: import ../features/${name} featureArgs) (
    builtins.attrNames (builtins.readDir ../features)
  );

  # One part of some features, as a single list. For example,
  # partOf "packages" included gives every package they install.
  partOf = part: builtins.concatMap (feature: lib.toList (feature.${part} or [ ]));

  # The features whose tags this configuration shares.
  included = builtins.filter (feature: lib.intersectLists tags feature.tags != [ ]) features;

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
