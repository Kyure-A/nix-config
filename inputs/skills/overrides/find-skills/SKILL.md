---
name: find-skills
description: Discover and compare agent skills when the user asks for a skill, reusable agent workflow, or capability extension. Ordinary requests to perform a task or explain how to do it do not require skill discovery.
---

# Find skills

Find a capability that addresses the user's actual gap, and explain what it adds to the current environment.

## Discover and compare

Inspect the skills, plugins, and callable tools already available in the session first. If they cover the need, identify the relevant capability and use it when the user also asked to perform the task. Do not search for or install a duplicate merely because a task has a familiar keyword.

If a gap remains, search the relevant upstream repositories or a registry such as [skills.sh](https://skills.sh/). Use the task and required behavior as search terms. Read candidate `SKILL.md` files and any resources needed to understand their dependencies and actions; registry popularity alone does not establish suitability.

Present the best matches with their source links, useful differences, maintenance evidence, and any dependency that affects the user's choice. Distinguish reusable instructions from an integration that actually provides account access or tools. Keep the comparison as small as the decision permits.

If no suitable skill is found, explain the gap. Continue any already requested work with existing capabilities where possible; suggest a custom skill only when a reusable workflow would add value.

## Install through the managed source

Searching for skills does not itself authorize installation. An explicit request to install or update one supplies that authorization; do not ask for it again.

kyre's external skills are managed by Nix. Locate the `dotnix` / `nix-config` repository, read its instructions, and make the change at the distribution source:

1. Add or update the pinned upstream input in `inputs/skills/flake.nix` and its lock file.
2. Register its source and enable the intended skill in `inputs/skills/default.nix`, checking target inclusion and existing names for duplicates.
3. Validate the selected skills and build the affected bundle. Review any unrelated pending changes before applying a system activation, and report whether the installed environment was actually updated.

Preserve an explicitly requested installation destination or alternative workflow. Otherwise do not bypass Nix with direct edits to deployed skill directories or global package-manager installation. When a required command is missing, check for `devenv.nix` or `flake.nix` and use the project environment; if neither exists, use `nix-shell` rather than installing the command globally.
