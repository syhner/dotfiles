# What every Mac gets.
args: {
  tags = [ "darwin" ];

  system = [
    ./base.nix
    (import ./homebrew.nix args)
  ];
}
