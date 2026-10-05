"""Derive the Blender preset from the pinned upstream standard declaration."""

from pathlib import Path
import sys


def replace_once(source, before, after):
    if source.count(before) != 1:
        raise ValueError("DSH standard preset changed; review the Blender derivation.")
    return source.replace(before, after, 1)


standard = Path(sys.argv[1]).read_text()
standard = replace_once(standard, "id: preset-standard", "id: preset-blender")
standard = replace_once(
    standard,
    "      name: '@deepseek-ai/dsh-agent-preset'\n",
    "      name: '@deepseek-ai/dsh-agent-preset'\n"
    "      disabled: !!js \"ctx.get('profileContext')?.name !== 'web'\"\n",
)
standard = replace_once(standard, "        id: standard\n", "        id: blender\n")
standard = replace_once(
    standard,
    "        order: 1\n",
    "        name: Blender\n"
    "        description: Clothing creation, scene inspection, and Blender automation with the shared project skills.\n"
    "        order: 10\n",
)
tools = Path(sys.argv[2]).read_text().splitlines()
tools = [line for line in tools if not line.startswith("%YAML ") and line != "---"]
Path(sys.argv[3]).write_text(
    standard.rstrip() + "\n" + "\n".join("          " + line for line in tools) + "\n"
)
