{ inputs }:
let
  inherit (inputs.nixpkgs-nixos) lib;
  inherit (import ./config.nix) username;

  # Every module. Each is a function of the build's arguments (see
  # moduleArgs), and a host includes the ones whose tags it shares.
  modulePaths = [
    ../modules/btop.nix
    ../modules/claude-code.nix
    ../modules/cli.nix
    ../modules/codex.nix
    ../modules/cryptomator.nix
    ../modules/deskflow
    ../modules/direnv
    ../modules/discord.nix
    ../modules/ghostty
    ../modules/git
    ../modules/gpg
    ../modules/grandperspective.nix
    ../modules/graphical.nix
    ../modules/hex.nix
    ../modules/kanata
    ../modules/linearmouse
    ../modules/nerd-fonts.nix
    ../modules/newsboat
    ../modules/nil.nix
    ../modules/nix.nix
    ../modules/nix-index-database.nix
    ../modules/nixd
    ../modules/obs.nix
    ../modules/obsidian.nix
    ../modules/opencode.nix
    ../modules/platform-darwin
    ../modules/platform-nixos
    ../modules/proton-vpn.nix
    ../modules/qbittorrent.nix
    ../modules/sops
    ../modules/spotify.nix
    ../modules/steam.nix
    ../modules/stylix.nix
    ../modules/t3code.nix
    ../modules/thunderbird.nix
    ../modules/tmux
    ../modules/utm.nix
    ../modules/utm-guest
    ../modules/vlc.nix
    ../modules/zed
    ../modules/zsh
  ];

  # Returns both the system and the home. Each of make.system and make.home
  # takes the one it wants, and Nix never evaluates the other.
  build =
    {
      platform,
      hostname ? null, # only the system needs one
      tags ? [ ],
      # Whether Home Manager runs on its own rather than as part of a system.
      standalone,
    }:
    let
      # Everything that differs between macOS and Linux.
      darwin = lib.hasSuffix "-darwin" platform;
      systemKey = if darwin then "darwin" else "nixos";
      nixpkgs = if darwin then inputs.nixpkgs-darwin else inputs.nixpkgs-nixos;
      makeSystem = if darwin then inputs.nix-darwin.lib.darwinSystem else lib.nixosSystem;
      homeDirectory = if darwin then "/Users/${username}" else "/home/${username}";

      # What every module takes. These are plain values rather than module
      # arguments, so a module can branch on any of them, pkgs included,
      # without infinite recursion. Only config still has to come from inside
      # the system or home part.
      moduleArgs = {
        inherit
          darwin
          homeDirectory
          hostname
          inputs
          pkgs
          standalone
          systemKey
          username
          ;
        repositoryPath = "${homeDirectory}/dotfiles";
        # Home Manager modules get a lib with Home Manager's own functions
        # added as lib.hm (lib.hm.dag, for example), so this lib has them too.
        lib = lib.extend (final: prev: { inherit (inputs.home-manager.lib) hm; });
      };

      # The modules this build includes. tags and unfree must not depend on
      # pkgs, because pkgs needs them first.
      included = builtins.filter (module: lib.intersectLists tags module.tags != [ ]) (
        map (path: import path moduleArgs) modulePaths
      );

      # One part of every included module, as a single list. For example,
      # partOf "unfree" gives every unfree package name.
      partOf = part: builtins.concatMap (module: lib.toList (module.${part} or [ ])) included;

      # nixpkgs for the platform, with nixpkgs-unstable as pkgs.unstable. Both
      # allow the unfree packages the modules name. Unstable no longer supports
      # Intel macOS, so there pkgs.unstable is the stable set.
      config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) (partOf "unfree");
      importNixpkgs =
        source: overlays:
        import source {
          system = platform;
          inherit config overlays;
        };
      pkgs = importNixpkgs nixpkgs [
        (final: prev: {
          unstable = if platform == "x86_64-darwin" then final else importNixpkgs inputs.nixpkgs-unstable [ ];
        })
      ];

      # The packages from every module, without any that don't run on this
      # platform.
      packages = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) (partOf "packages");

      # The home, whether the system manages Home Manager or it runs on its own.
      homeModules = [
        {
          home.username = username;
          home.homeDirectory = homeDirectory;

          # The Home Manager release this configuration is compatible with. Read
          # the Home Manager release notes before changing it.
          home.stateVersion = "26.05";

          # Let Home Manager install and manage itself.
          programs.home-manager.enable = true;
        }
      ]
      ++ partOf "home";
    in
    {
      # The system installs the packages and runs Home Manager as part of
      # itself.
      system = makeSystem {
        # For the host's own configuration.nix, which isn't a module.
        specialArgs = { inherit inputs hostname username; };
        modules = [
          ../hosts/${hostname}/configuration.nix
          {
            nixpkgs.pkgs = pkgs;
            environment.systemPackages = packages;
          }
          {
            imports = [ inputs.home-manager."${systemKey}Modules".home-manager ];

            # Home Manager reads the home directory from here.
            users.users.${username}.home = homeDirectory;
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username}.imports = homeModules;
          }
        ]
        ++ partOf "system";
      };

      # Home Manager on its own. With no system around, it installs the
      # packages itself.
      home = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ { home.packages = packages; } ] ++ homeModules;
      };
    };
in
{
  system = args: (build (args // { standalone = false; })).system;
  home = args: (build (args // { standalone = true; })).home;
}
