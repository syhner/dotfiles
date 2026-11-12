{
  config,
  lib,
  pkgs,
  settings,
  symlinkToCheckout,
  ...
}:
{
  config = lib.mkIf config.features.git.enable {
    # Commits and tags are signed.
    features.gpg.enable = true;

    packages = [
      pkgs.git
      pkgs.git-crypt
    ];

    home = {
      home.file.".gitconfig".source = symlinkToCheckout ./.gitconfig;

      xdg.configFile."git/user".text = ''
        [user]
          name = ${settings.gitUser.name}
          email = ${settings.gitUser.email}
          signingkey = ${settings.gitUser.signingKey}!
      '';

      # Where git looks for global ignores when core.excludesFile is unset.
      xdg.configFile."git/ignore".source = symlinkToCheckout ./.gitignore_global;
    };
  };
}
