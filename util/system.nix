{ lib }:
let
  supportedSystems = [
    "aarch64-darwin"
    "x86_64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];
in
{
  inherit supportedSystems;

  forAllSystems = lib.genAttrs supportedSystems;

  systemKey =
    { system, type }:
    if type == "home-manager" then
      "home"
    else if system == "x86_64-linux" || system == "aarch64-linux" then
      "nixos"
    else if system == "x86_64-darwin" || system == "aarch64-darwin" then
      "darwin"
    else
      throw "unsupported system: ${system}";

  kernel =
    system:
    if system == "x86_64-linux" || system == "aarch64-linux" then
      "linux"
    else if system == "x86_64-darwin" || system == "aarch64-darwin" then
      "darwin"
    else
      throw "unsupported system: ${system}";

  homeDirectory =
    { kernel, username }:
    if kernel == "linux" then
      "/home/${username}"
    else if kernel == "darwin" then
      "/Users/${username}"
    else
      throw "unsupported kernel: ${kernel}";

  configDirectory =
    { kernel, homeDirectory }:
    if kernel == "linux" then
      "${homeDirectory}/.config"
    else if kernel == "darwin" then
      "${homeDirectory}/Library/Application Support"
    else
      throw "unsupported kernel: ${kernel}";
}
