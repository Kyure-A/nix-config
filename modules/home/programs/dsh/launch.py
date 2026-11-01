"""Run DSH with the existing Pi credential store; never copy keys into Nix."""

import json
import os
from pathlib import Path
import re
import signal
import stat
import subprocess
import sys
import threading

# OAuth libraries can include a token response in a parse-error message.
# Redact only actual token fields; the private DSH browser startup URL is
# consumed by the opener and carries a separate, process-local UI token.
TOKEN_FIELDS = r"(?:access_token|refresh_token|id_token|accessToken|refreshToken|idToken|api_key|apiKey)"
QUOTED_TOKEN = re.compile(
    rf"(?P<prefix>[\"']?{TOKEN_FIELDS}[\"']?\s*[:=]\s*)"
    r"(?P<quote>[\"'])(?:\\.|(?!(?P=quote)).)*(?P=quote)?",
    re.IGNORECASE,
)
ESCAPED_TOKEN = re.compile(
    rf'(?P<prefix>\\"{TOKEN_FIELDS}\\"\s*:\s*\\")(?:.*?)(?:\\"|$)',
    re.IGNORECASE,
)


def redact_tokens(text, secrets=()):
    text = ESCAPED_TOKEN.sub(lambda match: match["prefix"] + '[REDACTED]\\"', text)
    text = QUOTED_TOKEN.sub(
        lambda match: match["prefix"] + match["quote"] + "[REDACTED]" + match["quote"],
        text,
    )
    for secret in secrets:
        if secret:
            text = text.replace(secret, "[REDACTED]")
    return text


def is_web(arguments):
    return bool(arguments) and (
        arguments[0] == "web"
        or arguments[:2] == ["--profile", "web"]
        or arguments[0] == "--profile=web"
    )


def run_web(command, environment):
    child = subprocess.Popen(
        command, env=environment, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    secrets = [environment.get(name, "") for name in ("VENICE_API_KEY", "STRATA_RVN_API_KEY")]

    def forward_signal(number, _frame):
        if child.poll() is None:
            child.send_signal(number)

    for number in (signal.SIGTERM, signal.SIGINT):
        signal.signal(number, forward_signal)

    def drain(source, target):
        for line in iter(source.readline, b""):
            target.buffer.write(redact_tokens(line.decode("utf-8", errors="replace"), secrets).encode())
            target.buffer.flush()
        source.close()

    drains = [
        threading.Thread(target=drain, args=(child.stdout, sys.stdout)),
        threading.Thread(target=drain, args=(child.stderr, sys.stderr)),
    ]
    for thread in drains:
        thread.start()
    code = child.wait()
    for thread in drains:
        thread.join()
    return 128 - code if code < 0 else code


def main():
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

    if not environment.get("STRATA_RVN_API_KEY"):
        credential_file = Path.home() / ".config/dsh/strata-rvn.key"
        if credential_file.exists():
            metadata = credential_file.lstat()
            if not stat.S_ISREG(metadata.st_mode) or metadata.st_mode & 0o077:
                sys.exit("Strata credential source must be a private regular file.")
            key = credential_file.read_text().strip()
            if not key or "\n" in key or "\r" in key:
                sys.exit("Strata credential file is invalid.")
            environment["STRATA_RVN_API_KEY"] = key

    command = sys.argv[1:]
    if is_web(command[1:]):
        sys.exit(run_web(command, environment))
    os.execvpe(command[0], command, environment)


if __name__ == "__main__":
    main()
