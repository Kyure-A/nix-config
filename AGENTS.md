# Nix Config

Personal NixOS and nix-darwin configuration using Nix Flakes and Home Manager.

- Read `README.org` for setup and per-host switch commands.
- The main branch is `master`; use Conventional Commits.
- Targets: `darwin` is `aarch64-darwin`; `wsl` and `x230` are `x86_64-linux`.
- Format changed Nix files with `nix fmt <paths>`.

## Agent Skills

Skills are managed by the local `inputs/skills/` flake, imported through `modules/home/default.nix`.

1. Add an external source input in `inputs/skills/flake.nix`.
2. Register it under `programs.agent-skills.sources` in `inputs/skills/default.nix`.
3. Select skills through `skills.explicit`; use `agents` for target-specific distribution and `transform` for local entrypoint overrides.
4. Validate and build the affected bundles before applying the relevant host configuration.
