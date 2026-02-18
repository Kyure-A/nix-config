{ pkgs, inputs, ... }:
let
  bun2nix = pkgs.callPackage ../../inputs/bun2nix { inherit pkgs; };
  programs = import ./programs { inherit pkgs; };
in
{
  imports = programs ++ [
    inputs.emacs.homeModules.${pkgs.system}.twist
    inputs.agent-skills.homeManagerModules.default
  ];
  home.packages = import ./pkgs { inherit pkgs bun2nix; };
  home.file = {
    ".claude/CLAUDE.md".source = ./AGENTS.md;
    ".codex/AGENTS.md".source = ./AGENTS.md;
  };
}
