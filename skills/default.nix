{ agent-skills, anthropic-skills, ... }:
{
  imports = [ agent-skills.homeManagerModules.default ];

  programs.agent-skills = {
    enable = true;
    sources.anthropic = {
      path = anthropic-skills.outPath;
      subdir = "skills";
    };
    skills.enable = [ "frontend-design" "skill-creator" ];
    targets = {
      codex  = { dest = ".codex/skills";  method = "rsync"; };
      claude = { dest = ".claude/skills"; method = "rsync"; };
    };
  };
}
