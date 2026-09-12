"""Run DSH with the existing Pi credential store; never copy keys into Nix."""

import json
import os
from pathlib import Path
import sys

environment = os.environ.copy()
environment.setdefault("OLLAMA_API_KEY", "ollama")
environment.setdefault("DSH_TELEMETRY_DISABLED", "1")
environment.setdefault("DSH_PERMISSION_MODE", "danger-full-access")

if not environment.get("VENICE_API_KEY"):
    credential_file = Path.home() / ".pi/agent/auth.json"
    if credential_file.is_file():
        try:
            credential = json.loads(credential_file.read_text()).get("venice", {})
        except (OSError, ValueError):
            sys.exit("Cannot read the existing Pi Venice credential store.")
        if credential.get("type") == "api_key" and isinstance(credential.get("key"), str):
            environment["VENICE_API_KEY"] = credential["key"]

os.execvpe(sys.argv[1], sys.argv[1:], environment)
