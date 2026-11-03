# What every Mac gets.
args: {
  tags = [ "darwin" ];

  system = [
    ./defaults.nix
    (import ./homebrew.nix args)
  ];
}
