{
  config,
  lib,
  pkgs,
  agent-skills,
  anthropic,
  find-skills,
  jev-cu,
  natural-japanese,
  ...
}:
let
  selfRepo = "${config.home.homeDirectory}/ghq/github.com/Kyure-A/self";
  materializeJev =
    builtins.replaceStrings
      [ "{{REPO_DIR}}" "{{SELF_REPO}}" ]
      [
        "${jev-cu}"
        selfRepo
      ];
  # CUA can import upstream observation/policy helpers, but cannot import the
  # process-spawning BWS bridge. Document the host-coordinated boundary.
  jevSkillSource = pkgs.runCommand "jev-cu-skill-source" { } ''
    mkdir -p "$out/jev-cu"
    cp -R ${jev-cu}/skill/jev-cu/. "$out/jev-cu/"
    chmod -R u+w "$out"
    cp ${pkgs.writeText "jev-cu-runtime.md" (materializeJev (builtins.readFile ./overrides/jev-cu/runtime.md))} \
      "$out/jev-cu/references/runtime.md"
  '';
in
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
        path = anthropic;
        subdir = "skills";
      };
      find-skills = {
        path = find-skills;
        subdir = "skills";
      };
      jev-cu.path = jevSkillSource;
      natural-japanese = {
        path = natural-japanese;
        subdir = "skills";
      };
    };
    skills.explicit = {
      doc-coauthoring = {
        from = "anthropic";
        transform = _: builtins.readFile ./overrides/doc-coauthoring/SKILL.md;
      };
      find-skills = {
        from = "find-skills";
        transform = _: builtins.readFile ./overrides/find-skills/SKILL.md;
      };
      jev-cu = {
        from = "jev-cu";
        agents = [ "codex" ];
        transform = _: materializeJev (builtins.readFile ./overrides/jev-cu/SKILL.md);
      };
      natural-japanese = {
        from = "natural-japanese";
        transform = _: builtins.readFile ./overrides/natural-japanese/SKILL.md;
      };
      # Codex supplies these workflows through its built-ins and plugins.
      pdf = {
        from = "anthropic";
        agents = [
          "claude"
          "dsh"
        ];
      };
      pptx = {
        from = "anthropic";
        agents = [
          "claude"
          "dsh"
        ];
      };
      skill-creator = {
        from = "anthropic";
        agents = [
          "claude"
          "dsh"
        ];
      };
    };
    # "link" manages only the bundle's own entries via home.file, so skills
    # installed into the same directories by other tools (e.g. the self
    # repository's skills-install) are left untouched. copy-tree/symlink-tree
    # would rsync --delete them on every switch.
    targets = {
      codex = {
        dest = ".codex/skills";
        structure = "link";
      };
      claude = {
        dest = ".claude/skills";
        structure = "link";
      };
      dsh = {
        dest = ".dsh/skills";
        structure = "link";
      };
    };
  };
}
