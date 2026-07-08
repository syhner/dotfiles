{
  pkgs,
  platform,
  ...
}:

if (platform == "nixos" || platform == "darwin") then
  {
    environment.systemPackages = [
      pkgs.zed-editor
    ];
  }
else
  { }
