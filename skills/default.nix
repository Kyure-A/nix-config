{
  lib,
  agent-skills,
  personal,
  anthropic,
  vercel,
  remotion,
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
      personal = {
        path = personal;
      };
      anthropic = {
        path = anthropic;
        subdir = "skills";
      };
      vercel = {
        path = vercel;
        subdir = "skills";
      };
      remotion = {
        path = remotion;
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
