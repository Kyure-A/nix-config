{ pkgs, inputs, ... }:
let
  bun2nix = pkgs.callPackage ../../inputs/bun2nix { inherit pkgs; };
  glidePkg =
    if pkgs.stdenv.isDarwin then inputs.glide.packages.${pkgs.stdenv.hostPlatform.system}.default else null;
  programs = import ./programs { inherit pkgs; };
in
{
  imports = programs ++ [
    inputs.emacs.homeModules.twist
    inputs.agent-skills.homeManagerModules.default
    inputs.sheldon.homeManagerModules.default
  ];
  home.packages = import ./pkgs {
    inherit pkgs bun2nix glidePkg;
  };
  home.file = {
    ".claude/CLAUDE.md".source = ./AGENTS.md;
    ".codex/AGENTS.md".source = ./AGENTS.md;
    ".config/agents-md/template.md".source = ./AGENTS.md.template;
  };
}
