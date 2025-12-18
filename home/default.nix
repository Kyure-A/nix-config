{
  system,
  nixpkgs,
  overlays,
  emacs-d,
}:
let
  pkgs = import nixpkgs {
    inherit system overlays node2nix;
    config.allowUnfree = true;
  };

  node2nix = pkgs.callPackage ../node2nix { inherit pkgs; };

  programs = import ./programs { inherit pkgs node2nix; };
in
{
  imports = programs ++ [ emacs-d.homeModules.${system}.twist ];
  home.packages = import ./pkgs { inherit pkgs; };

  home.stateVersion = "25.05";
}
