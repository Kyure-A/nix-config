# Child flake Home Manager module for skills catalog.
{ anthropic-skills, ... }:
{
  programs.agent-skills = {
    sources.anthropic = {
      path = anthropic-skills.outPath;
      subdir = "skills";
    };
    skills.enable = [ "frontend-design" "skill-creator" ];
  };
}
