{
  machine,
  pkgs,
  symlinkToCheckout,
  ...
}:
{
  tags = [ "gui" ];

  packages = [
    # nixpkgs can't build the macOS app, so it repackages the official one.
    (if machine.platform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty)
  ];

  home = {
    xdg.configFile."ghostty/config".source = symlinkToCheckout ./config;
  };
}
