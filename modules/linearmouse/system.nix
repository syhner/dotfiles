{
  kernel,
  ...
}:

if (kernel == "darwin") then
  {
    homebrew.casks = [
      "linearmouse"
    ];
  }
else
  { }
