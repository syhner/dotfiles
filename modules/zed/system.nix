{
  pkgs,
  kernel,
  ...
}:

if (kernel == "linux" || kernel == "darwin") then
  {
    environment.systemPackages = [
      pkgs.zed-editor
    ];
  }
else
  { }
