{ symlinkToCheckout, ... }:
{
  tags = [ "base" ];

  # Leave compinit to completionInit below, which Home Manager runs after
  # extending fpath, rather than running it twice.
  system.programs.zsh.enableGlobalCompInit = false;

  home =
    { config, lib, ... }:
    let
      zcompdump = "${config.programs.zsh.dotDir}/.zcompdump";
    in
    {
      # don't let home-manager manage ~/.zshrc as other programs will want to
      # write to it, instead let it manage a seperate directory and source ~/.zshrc
      # from there (same applies to other zsh files like .zshenv)

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
      };

      home.activation.removeZcompdump = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run rm -f ${lib.escapeShellArg zcompdump} ${lib.escapeShellArg "${zcompdump}.zwc"}
      '';

      programs.zoxide.enable = true;
      programs.zoxide.enableZshIntegration = true;

      home.file.".zshrc".source = symlinkToCheckout ./.zshrc;
    };
}
