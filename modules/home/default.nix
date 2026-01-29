{ pkgs, inputs, ... }:
let
  bun2nix = pkgs.callPackage ../../inputs/bun2nix { inherit pkgs; };
  programs = import ./programs { inherit pkgs; };
in
{
  imports = programs ++ [
    inputs.emacs-d.homeModules.${pkgs.system}.twist
    inputs.skills-config.homeManagerModules.default
  ];
  home.packages = import ./pkgs { inherit pkgs bun2nix; };
}
