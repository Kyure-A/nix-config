{
  system,
  nixpkgs,
  overlays,
  inputs,
  emacs-d,
}:
let
  pkgs = import nixpkgs {
    inherit system overlays;
    config.allowUnfree = true;
  };

  bun2nix = pkgs.callPackage ../bun2nix { inherit pkgs; };

  programs = import ./programs { inherit pkgs bun2nix inputs; };
in
{
  imports = programs ++ [
    emacs-d.homeModules.${system}.twist
    inputs.skills-config.homeManagerModules.default
  ];
  home.packages = import ./pkgs { inherit pkgs; };

  home.stateVersion = "25.05";
}
