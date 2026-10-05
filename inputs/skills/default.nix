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
  # Runtime references also contain placeholders; a SKILL.md transform alone
  # would leave an unusable example. Scripts stay in the pinned upstream source.
  jevSkillSource = pkgs.runCommand "jev-cu-skill-source" { } ''
    mkdir -p "$out/jev-cu"
    cp -R ${jev-cu}/skill/jev-cu/. "$out/jev-cu/"
    chmod -R u+w "$out"
    substituteInPlace "$out/jev-cu/references/runtime.md" \
      --replace-fail '{{REPO_DIR}}' '${jev-cu}' \
      --replace-fail 'var jevResult = await jevLoop.runTask({' 'var jevBws = await import(jevUrl.pathToFileURL("${selfRepo}/scripts/jev-cu-bws.mjs").href);
    var jevPath = await import("node:path");
    var jevOs = await import("node:os");
    var jevResult = await jevLoop.runTask({
      decide: jevBws.createBwsDecider({ repoDir }),
      traceDir: jevPath.join(process.env.XDG_STATE_HOME || jevPath.join(jevOs.homedir(), ".local", "state"), "jev-cu", "runs"),'
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
        transform =
          { original, ... }:
          builtins.replaceStrings
            [
              "{{REPO_DIR}}"
              "项目 `.env.local` 或环境变量 `TYPESAFE_API_KEY`；只检查是否存在，不输出值。"
              "技能源文件：项目 `skill/jev-cu/`。修改后运行 `node scripts/install-skill.mjs` 同步到已安装目录；不要维护两套正文。"
              "轨迹在项目 `runs/`。"
            ]
            [
              "${jev-cu}"
              "BWS 项目 `self-automation` 中的 `TYPESAFE_API_KEY`。通过 `${selfRepo}/scripts/jev-cu-bws.mjs` 的 `createBwsDecider({ repoDir })` 传给 `runTask` 的 `decide`；密钥仅注入子进程，不写入文件或传入 CUA。配置和 profile 由 self 管理。"
              "技能由 dotnix 的 `inputs/skills` 管理并固定上游版本；更新 Nix 源和 lock 文件后构建、部署，不运行上游安装脚本覆盖已部署文件。"
              "每次 `runTask` 都必须指定可写的 `traceDir`，使用 `$XDG_STATE_HOME/jev-cu/runs` 或 `~/.local/state/jev-cu/runs`；固定的 Nix 源是只读的。"
            ]
            original;
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
