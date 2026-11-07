{ repositoryPath, symlinkToCheckout, ... }:
{
  tags = [ "base" ];

  # Leave compinit to completionInit below, which Home Manager runs after
  # extending fpath, rather than running it twice.
  system.programs.zsh.enableGlobalCompInit = false;

  home =
    { config, ... }:
    {
      # don't let home-manager manage ~/.zshrc as other programs will want to
      # write to it, instead let it manage a seperate directory and source ~/.zshrc
      # from there (same applies to other zsh files like .zshenv)

      programs.zsh = {
        enable = true;
        dotDir = "${config.xdg.configHome}/zsh-home-manager";
        # For nixswitch in .zshrc.
        sessionVariables.DOTFILES = repositoryPath;
        # Reuse the completion dump on normal startups to avoid compinit's audit
        # overhead, but refresh it daily so new and changed completions are detected.
        completionInit = ''
          autoload -Uz compinit
          zmodload zsh/datetime
          zmodload zsh/stat

          typeset -A _zcompstat
          typeset _zcompdump="''${ZDOTDIR:-$HOME}/.zcompdump"

          if [[ ! -s $_zcompdump ]] ||
             ! zstat -H _zcompstat +mtime -- $_zcompdump ||
             (( EPOCHSECONDS - _zcompstat[mtime] > 86400 )); then
            compinit -d "$_zcompdump"
            # compinit only rewrites the dump when the completions changed, so
            # mark it checked, or every startup after the first day is slow.
            touch -- "$_zcompdump"
          else
            compinit -C -d "$_zcompdump"
          fi

          unset _zcompstat _zcompdump
        '';
        initContent = ''
          source ~/.zshrc
        '';

        syntaxHighlighting.enable = true;
        autosuggestion.enable = true;
      };

      programs.zoxide.enable = true;
      programs.zoxide.enableZshIntegration = true;

      home.file.".zshrc".source = symlinkToCheckout ./.zshrc;
    };
}
