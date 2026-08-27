{
  config,
  repositoryPath,
  homeDirectory,
  ...
}:

{
  # don't let home-manager manage ~/.zshrc as other programs will want to write to it, instead let it manage a seperate directory and source ~/.zshrc from there (same applies to other zsh files like .zshenv)

  programs.zsh = {
    enable = true;
    dotDir = "${homeDirectory}/.config/zsh-home-manager";
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
    historySubstringSearch.enable = true;
  };

  programs.zoxide.enable = true;
  programs.zoxide.enableZshIntegration = true;

  home.file.".zshrc".source =
    config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/zsh/.zshrc";
}
