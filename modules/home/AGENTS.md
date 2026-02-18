# Agent Instructions
## Core Principles

### Do NOT maintain backward compatibility
unless explicitly requested. Break things boldly.

### Keep this file under 20-30 lines of instructions
Every line competes for the agent's limited context budget (~150-200 total).

### Regarding command execution
If you're trying to run a command and it doesn't exist, first check if the directory contains either of these files:
- `devenv.nix`
- `flake.nix`

If neither exists, please use `nix-shell` to run the command. Do not install the command globally.
