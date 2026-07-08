{
  config,
  repositoryPath,
  ...
}:

{
  # don't let home-manager manage ~/.zshrc as other programs will want to write to it, instead let it manage a seperate directory and source ~/.zshrc from there (same applies to other zsh files like .zshenv)

  programs.zsh = {
    enable = true;
    dotDir = "${config.home.homeDirectory}/.config/zsh-home-manager";
    initContent = ''
      source ~/.zshrc
    '';

    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    historySubstringSearch.enable = true;
  };

  home.file.".zshrc".source =
    config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/nix/modules/zsh/.zshrc";
}
