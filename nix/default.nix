# Builds the configurations in flake.nix: NixOS and nix-darwin systems, which
# integrate Home Manager, and standalone Home Manager homes. A configuration
# passes its platform and the modules it wants (see nix/modules.nix). Also
# passes on the modules and username, so flake.nix imports only this file.
{ inputs }:
let
  inherit (inputs.nixpkgs-nixos) lib;
  inherit (import ./config.nix) username;

  # What systems and homes build from, given the platform and the modules.
  common = platform: modules: rec {
    # A part of every module, in the order the configuration lists them.
    partOf = part: builtins.concatMap (module: lib.toList (module.${part} or [ ])) modules;

    pkgs = import ./pkgs.nix { inherit inputs platform modules; };
    darwin = pkgs.stdenv.isDarwin;
    homeDirectory = if darwin then "/Users/${username}" else "/home/${username}";
    specialArgs = {
      inherit inputs username;
      repositoryPath = "${homeDirectory}/dotfiles";
    };

    # Every home, integrated or standalone.
    home = {
      home.username = username;
      home.homeDirectory = homeDirectory;

      # The Home Manager release this configuration is compatible with. Read the
      # Home Manager release notes before changing it.
      home.stateVersion = "26.05";

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;
    };
  };
in
{
  inherit username;

  modules = import ./modules.nix;

  mkSystem =
    {
      platform,
      hostname,
      modules ? [ ],
    }:
    let
      c = common platform modules;
      systemKey = if c.darwin then "darwin" else "nixos";
      build = {
        darwin = inputs.nix-darwin.lib.darwinSystem;
        nixos = lib.nixosSystem;
      };
    in
    build.${systemKey} {
      specialArgs = c.specialArgs // {
        inherit hostname systemKey;
      };
      modules = [
        ../hosts/${hostname}/configuration.nix
        { nixpkgs.pkgs = c.pkgs; }
        (import ./packages.nix {
          inherit modules;
          standalone = false;
        })
        {
          imports = [ inputs.home-manager."${systemKey}Modules".home-manager ];
          # Home Manager reads the home directory from here.
          users.users.${username}.home = c.homeDirectory;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = c.specialArgs;
          home-manager.users.${username}.imports = [ c.home ] ++ c.partOf "home";
        }
      ]
      ++ c.partOf "system";
    };

  mkHome =
    {
      platform,
      modules ? [ ],
    }:
    let
      c = common platform modules;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit (c) pkgs;
      extraSpecialArgs = c.specialArgs;
      modules = [
        c.home
        (import ./packages.nix {
          inherit modules;
          standalone = true;
        })
      ]
      ++ c.partOf "home"
      ++ c.partOf "standalone";
    };
}
