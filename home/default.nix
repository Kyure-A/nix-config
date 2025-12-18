{
  system,
  nixpkgs,
  overlays,
  emacs-d,
  emacs-config,
  earlyInitEl,
}:
let
  pkgs = import nixpkgs {
    inherit system overlays node2nix;
    config.allowUnfree = true;
  };

  node2nix = pkgs.callPackage ../node2nix { inherit pkgs; };

  programs = import ./programs { inherit pkgs emacs-config node2nix earlyInitEl; };
in
{
  imports = programs ++ [ emacs-d.homeModules.${system}.twist ];
  home.packages = import ./pkgs { inherit pkgs; };

  home.stateVersion = "25.05";
}
