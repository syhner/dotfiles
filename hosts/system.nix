{
  hostname,
  ...
}:

{
  imports = [ ./${hostname}/configuration.nix ];
}
