{
  platform,
  ...
}:

if (platform == "darwin") then
  {
    homebrew.casks = [
      "linearmouse"
    ];
  }
else
  { }
