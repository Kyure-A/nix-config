{
  lib,
  agent-skills,
  # personal,
  anthropic,
  vercel,
  find-skills,
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
      # personal = {
      #   path = personal;
      # };
      anthropic = {
        path = anthropic;
        subdir = "skills";
      };
      vercel = {
        path = vercel;
        subdir = "skills";
      };
      find-skills = {
        path = find-skills;
        subdir = "skills";
      };
    };
    skills.enable = [
      "doc-coauthoring"
      "find-skills"
      "pdf"
      "pptx"
      "skill-creator"
    ];
    # skills.enableAll = [ "personal" ];
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
