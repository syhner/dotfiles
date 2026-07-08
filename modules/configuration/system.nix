{
  platform,
  hostname,
  ...
}:
if (platform == "nixos" || platform == "darwin") then
  {
    imports = [ ./${hostname}/configuration.nix ];
  }
else
  { }
