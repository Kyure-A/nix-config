"""Seed writable rules and remove obsolete Mac-only profile bundles."""

import json
import os
from pathlib import Path
import sys
import tempfile


RETIRED_BUNDLE = "@local/dsh-host"


def initialize_profiles(home, agents_source):
    agents = home / "AGENTS.md"
    if agents.is_symlink() or (agents.exists() and not agents.is_file()):
        raise ValueError("DSH AGENTS.md must be a writable regular file")
    if not agents.exists():
        descriptor = os.open(agents, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(descriptor, "w") as target:
            target.write(agents_source.read_text())
    for name in ("web", "headless"):
        directory = home / "profiles" / name
        path = directory / "package.json"
        if not path.exists():
            continue
        manifest = json.loads(path.read_text())
        profile = manifest.setdefault("dsh", {}).setdefault("profile", {})
        bundles = profile.get("bundles", [])
        if not isinstance(bundles, list) or not all(isinstance(item, str) for item in bundles):
            raise ValueError(f"Invalid DSH bundle list in {path}")
        if RETIRED_BUNDLE in bundles:
            profile["bundles"] = [bundle for bundle in bundles if bundle != RETIRED_BUNDLE]
            with tempfile.NamedTemporaryFile(mode="w", dir=directory, delete=False) as target:
                json.dump(manifest, target, indent=2)
                target.write("\n")
                temporary = target.name
            os.replace(temporary, path)


if __name__ == "__main__":
    initialize_profiles(Path(sys.argv[1]), Path(sys.argv[2]))
