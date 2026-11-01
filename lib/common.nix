{
  inputs,
  system,
  defaultModuleBehaviour,
  features,
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

  resolvedFeatures = import ./defaults.nix {
    inherit
      system
      isLinux
      isDarwin
      defaultModuleBehaviour
      features
      ;
  };

  specialArgs = {
    features = resolvedFeatures;
    inherit
      inputs
      username
      homeDirectory
      configDirectory
      repositoryPath
      isLinux
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
    features = resolvedFeatures;
  }
