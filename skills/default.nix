{ lib, agent-skills, anthropic-skills, ... }:
{
  imports = [
    (import "${agent-skills.outPath}/modules/home-manager/agent-skills.nix" {
      inherit lib;
      inputs = {};
    })
  ];

  programs.agent-skills = {
    enable = true;
    sources.anthropic = {
      path = anthropic-skills;
      subdir = "skills";
    };
    skills.enable = [ "frontend-design" "skill-creator" ];
    targets = {
      codex  = { dest = ".codex/skills";  structure = "copy-tree"; };
      claude = { dest = ".claude/skills"; structure = "copy-tree"; };
    };
  };
}
