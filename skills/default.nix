{
  lib,
  agent-skills,
  anthropic-skills,
  vercel-skills,
  remotion-skills,
  my-skills,
  ...
}:
{
  imports = [
    (import "${agent-skills.outPath}/modules/home-manager/agent-skills.nix" {
      inherit lib;
      inputs = { };
    })
  ];

  programs.agent-skills = {
    enable = true;
    sources = {
      anthropic = {
        path = anthropic-skills;
        subdir = "skills";
      };
      personal = {
        path = my-skills;
      };
      vercel = {
        path = vercel-skills;
        subdir = "skills";
      };
      remotion = {
        path = remotion-skills;
        subdir = "skills";
      };
    };
    skills.enable = [
      "frontend-design"
      "pdf"
      "pptx"
      "skill-creator"
      "remotion"
    ];
    skills.enableAll = [ "personal" ];
    targets = {
      codex = {
        dest = ".codex/skills";
        structure = "copy-tree";
      };
      claude = {
        dest = ".claude/skills";
        structure = "copy-tree";
      };
    };
  };
}
