# Nix Config

Kyure_A's personal NixOS + nix-darwin dotfiles managed via **Nix Flake** and **Home Manager**.

## Quick Reference

See `README.org` for full documentation and per-host setup notes.

## Git Workflow

- **Main branch**: `master`
- This repository uses Conventional Commits for its commit rules.

## Agent Skills (agent-skills-nix)

Skills are configured via the local flake in `skills/`.

- **Configuration**: `skills/flake.nix`, `skills/default.nix`
- **Home Manager import**: `home/default.nix`

### Adding a new external skill

1. Add a flake input in `skills/flake.nix`.
2. Register the source in `skills/default.nix` under `programs.agent-skills.sources`.
3. Enable the skill in `programs.agent-skills.skills.enable`.
4. Rebuild using the appropriate switch command (see Core Commands).

### Current skills

Enabled in `skills/default.nix`

## System Targets

- **darwin**: `aarch64-darwin`
- **wsl**: `x86_64-linux`
- **x230**: `x86_64-linux`
