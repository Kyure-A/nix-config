"""Validate the current private startup URL, then hand it to macOS on stdin."""

from pathlib import Path
import re
import subprocess
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.request import build_opener, HTTPRedirectHandler, ProxyHandler, Request


STARTUP_URL = re.compile(r"^dsh web: (http://127\.0\.0\.1:3080/\?token=[A-Za-z0-9_-]+)(?:\s|$)")


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, request, response, code, message, headers, url):
        return None


def current_url(path):
    try:
        lines = path.read_text().splitlines()
    except OSError:
        return None
    for line in reversed(lines):
        match = STARTUP_URL.match(line)
        if match:
            return match.group(1)
    return None


def is_ready(url):
    # An old URL must receive 401; only this process's token receives a cookie.
    # Disable proxies, redirects, and cookie persistence for this local probe.
    opener = build_opener(ProxyHandler({}), NoRedirect())
    try:
        opener.open(Request(url), timeout=2).close()
    except HTTPError as response:
        if response.code != 303 or response.headers.get("Location") != "./":
            response.close()
            return False
        cookie = response.headers.get("Set-Cookie", "").split(";", 1)[0]
        response.close()
        if not cookie:
            return False
        try:
            with opener.open(
                Request(url.partition("?")[0], headers={"Cookie": cookie}), timeout=2
            ) as index:
                return index.status == 200 and index.headers.get_content_type() == "text/html"
        except (HTTPError, URLError, TimeoutError):
            return False
    except (URLError, TimeoutError):
        return False
    return False


def main():
    path = Path(sys.argv[1])
    deadline = time.monotonic() + 60
    while time.monotonic() < deadline:
        url = current_url(path)
        if url is not None and is_ready(url):
            subprocess.run(
                ["/usr/bin/osascript", "-l", "JavaScript", sys.argv[2]],
                input=url.encode(),
                check=True,
            )
            return
        time.sleep(1)
    sys.exit("DSH did not become ready. Check ~/.local/state/dsh/web.log.")


if __name__ == "__main__":
    main()
