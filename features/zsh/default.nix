{
  config,
  lib,
  machine,
  pkgs,
  settings,
  symlinkToCheckout,
  ...
}:
{
  config = lib.mkIf config.features.zsh.enable {
    system = [
      # Leave compinit to completionInit below, which Home Manager runs after
      # extending fpath, rather than running it twice.
      { programs.zsh.enableGlobalCompInit = false; }
    ]
    # the login shell, as macOS has already
    ++ lib.optional machine.platform.isLinux {
      programs.zsh.enable = true;
      users.users.${settings.user.name}.shell = pkgs.zsh;
    };

    home =
      { config, lib, ... }:
      let
        zcompdump = "${config.programs.zsh.dotDir}/.zcompdump";
      in
      {
        # Home Manager's zsh files go in dotDir, and source ~/.zshrc (linked to the checkout)

        programs.zsh = {
          enable = true;
          dotDir = "${config.xdg.configHome}/zsh-home-manager";
          # Skip compinit's check for new completions: they only change with
          # a switch, which deletes the dump (below), so it's remade then.
          completionInit = ''
            autoload -Uz compinit
            compinit -C -d ${lib.escapeShellArg zcompdump}
          '';
          initContent = ''
            source ~/.zshrc
          '';

          syntaxHighlighting.enable = true;
          autosuggestion.enable = true;

          history.ignoreAllDups = true;
        };

        home.activation.removeZcompdump = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run rm -f ${lib.escapeShellArg zcompdump} ${lib.escapeShellArg "${zcompdump}.zwc"}
        '';

        programs.zoxide.enable = true;

        home.file.".zshrc".source = symlinkToCheckout ./.zshrc;
      };
  };
}
