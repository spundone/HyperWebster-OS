#!/bin/sh
# patch-glyphs.sh — fix empty/"?" icons in Nexus menus and Super+Space actions.
# Idempotent. Runs as root against the installed caelestia/nosignal shell.
set -eu

NEXUS=${NEXUS:-/etc/xdg/quickshell/caelestia}
GLYPHS=${GLYPHS:-$NEXUS/services/Glyphs.qml}

[ -f "$GLYPHS" ] || { echo "Glyphs.qml not found at $GLYPHS — skipping"; exit 0; }

python3 - "$GLYPHS" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
orig = text
marker_empty = "HYPERWEBSTER_GLYPHS_EMPTY_ICON"
marker_launcher = "HYPERWEBSTER_LAUNCHER_GLYPHS"

# 1) Empty icon name → "" (not question-mark fallback)
old_get = """    function get(name: string): string {
        return root.map[name] ?? root.cp(0xf128);
    }"""
new_get = f"""    function get(name: string): string {{
        // {marker_empty}
        if (!name)
            return "";
        return root.map[name] ?? root.cp(0xf128);
    }}"""

if marker_empty in text or re.search(r"if\s*\(\s*!name\s*\)", text):
    print(f":: {path.name} already has empty-icon fix")
elif old_get in text:
    text = text.replace(old_get, new_get, 1)
    print(f":: patched get() empty-icon handling in {path}")
else:
    pat = re.compile(
        r"function get\(name: string\): string \{\s*"
        r"return root\.map\[name\] \?\? root\.cp\(0xf128\);\s*\}",
        re.M,
    )
    if pat.search(text):
        text, n = pat.subn(new_get.strip(), text, count=1)
        print(f":: patched get() (regex) in {path}" if n else f"WARNING: get() regex failed in {path}")
    else:
        print(f"WARNING: get() shape unchanged/unknown in {path}", file=sys.stderr)

# 2) Ensure "check" is mapped
if '"check":' not in text and "'check':" not in text:
    m = re.search(r"(\n    \}\n\n    function get\()", text)
    if m:
        before = text[: m.start()].rstrip()
        if not before.endswith(","):
            before += ","
        text = before + '\n        "check": root.cp(0xf00c)\n' + text[m.start() :]
        print(f":: added check glyph to {path}")
    else:
        print(f"WARNING: could not insert check glyph in {path}", file=sys.stderr)
else:
    print(f":: check glyph already present in {path.name}")

# 3) Launcher action icons (Super+Space >) from launcherconfig.hpp
launcher_glyphs = {
    "calculate": "0xf1ec",
    "colors": "0xf53f",
    "casino": "0xf522",
    "light_mode": "0xf185",
    "cached": "0xf021",
    "exit_to_app": "0xf08b",
    "help_outline": "0xf059",
    "text_fields": "0xf031",
    "wb_sunny": "0xf185",
    "brightness_5": "0xf185",
    "tonality": "0xf042",
    "style": "0xf53f",
    "border_style": "0xf247",
}

def insert_into_map(src: str, entries: dict[str, str], marker: str) -> str:
    missing = {k: v for k, v in entries.items() if f'"{k}":' not in src}
    if marker in src:
        print(f":: {path.name} already has {marker}")
        return src
    if not missing:
        print(f":: all requested glyphs already present")
        return src
    m = re.search(r"\n    \}\n\n    function get\(", src)
    if not m:
        print(f"WARNING: map close before get() not found", file=sys.stderr)
        return src
    before = src[: m.start()].rstrip()
    # Ensure the previous map entry ends with a comma (ignore trailing // comments).
    blines = before.splitlines()
    last = blines[-1]
    code = last.split("//", 1)[0].rstrip()
    if code and not code.endswith(",") and not code.endswith("{"):
        if "//" in last:
            left, right = last.split("//", 1)
            blines[-1] = left.rstrip() + ", //" + right
        else:
            blines[-1] = last + ","
        before = "\n".join(blines)
    lines = [f"        // {marker}", "        // Super+Space launcher actions + common Settings icons"]
    for name, cp in sorted(missing.items()):
        lines.append(f'        "{name}": root.cp({cp}),')
    # Drop trailing comma on last inserted line — QML allows trailing commas,
    # but keep consistent with surrounding style (last map entry often has none).
    lines[-1] = lines[-1].rstrip(",")
    block = "\n".join(lines)
    out = before + "\n" + block + src[m.start() :]
    print(f":: added {len(missing)} glyphs ({', '.join(sorted(missing))})")
    return out

text = insert_into_map(text, launcher_glyphs, marker_launcher)

# Ensure "code" exists (Appearance mono picker)
if '"code":' not in text:
    text = insert_into_map(text, {"code": "0xf121"}, "HYPERWEBSTER_CODE_GLYPH")

if text != orig:
    bak = path.with_suffix(path.suffix + ".pre-hyperwebster-glyphs")
    if not bak.exists():
        bak.write_text(orig)
    path.write_text(text)
    print(f":: wrote {path}")
else:
    print(f":: {path.name} unchanged")
PY
