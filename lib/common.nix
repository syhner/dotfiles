{
  inputs,
  system,
  modules,
}:
let
  username = import ../config/username.nix;

  isLinux = inputs.nixpkgs-nixos.lib.hasSuffix "-linux" system;
  isDarwin = inputs.nixpkgs-nixos.lib.hasSuffix "-darwin" system;

  nixpkgs = if isDarwin then inputs.nixpkgs-darwin else inputs.nixpkgs-nixos;

  homeDirectory = if isDarwin then "/Users/${username}" else "/home/${username}";
  configDirectory =
    if isDarwin then "${homeDirectory}/Library/Application Support" else "${homeDirectory}/.config";
  repositoryPath = "${homeDirectory}/dotfiles";

  selected = (import ./modules.nix).select modules;

  specialArgs = {
    inherit
      inputs
      username
      homeDirectory
      configDirectory
      repositoryPath
      isDarwin
      ;
  };

in
if !(isLinux || isDarwin) then
  throw "unsupported system: ${system}"
else
  {
    inherit
      nixpkgs
      isDarwin
      username
      specialArgs
      ;
    modules = selected;
  }
