{ inputs }:
{
  system, # for example "aarch64-darwin"
  hostname ? null, # none for a standalone home
  tags,
  standalone ? false, # whether Home Manager runs on its own rather than in a system
  allowUnfree ? false,
}:

assert standalone || hostname != null || throw "a system needs a hostname";

let
  inherit (inputs.nixpkgs-nixos) lib;
  inherit (import ./config.nix) username;

  # The platform's details, such as platform.isDarwin, platform.isx86_64
  # and platform.system (the "aarch64-darwin" string). Everything that
  # differs by platform checks this.
  platform = lib.systems.elaborate system;

  # The nixpkgs release for the platform.
  nixpkgs = if platform.isDarwin then inputs.nixpkgs-darwin else inputs.nixpkgs-nixos;

  config = { inherit allowUnfree; };

  # nixpkgs-unstable as pkgs.unstable.
  overlay = final: prev: {
    unstable = import inputs.nixpkgs-unstable { inherit config system; };
  };

  pkgs = import nixpkgs {
    inherit config system;
    overlays = [ overlay ];
  };

  # What every module takes. These are plain values rather than module
  # arguments, so a module can branch on any of them, pkgs included, without
  # infinite recursion. Only config still has to come from inside the system
  # or home part.
  homeDirectory = if platform.isDarwin then "/Users/${username}" else "/home/${username}";
  moduleArgs = {
    inherit
      homeDirectory
      hostname
      inputs
      lib
      pkgs
      platform
      standalone
      username
      ;
    repositoryPath = "${homeDirectory}/dotfiles";
  };

  # Every module (each file or directory in modules/), called with what it
  # takes.
  modules = map (name: import ../modules/${name} moduleArgs) (
    builtins.attrNames (builtins.readDir ../modules)
  );

  # One part of some modules, as a single list. For example,
  # partOf "packages" included gives every package they install.
  partOf = part: builtins.concatMap (module: lib.toList (module.${part} or [ ]));

  # The modules whose tags this configuration shares.
  included = builtins.filter (module: lib.intersectLists tags module.tags != [ ]) modules;

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

      users.users.${username}.home = homeDirectory;
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${username}.imports = homeModules;
    }
  ]
  ++ partOf "system" included;

  # The home. With no system around, it installs the packages itself.
  homeModules =
    lib.optional standalone { home.packages = packages; }
    ++ [
      {
        home.username = username;
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
    specialArgs = { inherit inputs hostname username; };
    modules = systemModules;
  }
