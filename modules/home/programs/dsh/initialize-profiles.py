"""Attach inherited Nix defaults without replacing writable profile state."""

import json
import os
from pathlib import Path
import sys
import tempfile


DEFAULTS_BUNDLE = "@local/dsh-defaults"
TEMPLATES = {
    "web": ["@deepseek-ai/dsh-base", "@deepseek-ai/dsh-web-app"],
    "headless": ["@deepseek-ai/dsh-base", "@deepseek-ai/dsh-headless"],
}


def initialize_profiles(home):
    for name, template in TEMPLATES.items():
        directory = home / "profiles" / name
        directory.mkdir(mode=0o700, parents=True, exist_ok=True)
        path = directory / "package.json"
        if path.exists():
            manifest = json.loads(path.read_text())
        else:
            manifest = {"name": f"dsh-profile-{name}", "private": True, "dependencies": {}}
        profile = manifest.setdefault("dsh", {}).setdefault("profile", {})
        bundles = profile.setdefault("bundles", list(template))
        if not isinstance(bundles, list) or not all(isinstance(item, str) for item in bundles):
            raise ValueError(f"Invalid DSH bundle list in {path}")
        if DEFAULTS_BUNDLE not in bundles:
            bundles.append(DEFAULTS_BUNDLE)
            with tempfile.NamedTemporaryFile(mode="w", dir=directory, delete=False) as target:
                json.dump(manifest, target, indent=2)
                target.write("\n")
                temporary = target.name
            os.replace(temporary, path)
        patch = directory / "cordis.patch.yml"
        if not patch.exists():
            patch.write_text("# Writable profile overrides, applied after bundle defaults.\n[]\n")
            patch.chmod(0o600)
        workspace = directory / "pnpm-workspace.yaml"
        if not workspace.exists():
            workspace.write_text("packages:\n  - .\n\nnodeLinker: hoisted\nautoInstallPeers: false\n")
            workspace.chmod(0o600)


if __name__ == "__main__":
    initialize_profiles(Path(sys.argv[1]))
