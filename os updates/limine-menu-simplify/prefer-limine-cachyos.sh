#!/usr/bin/env bash
# prefer-limine-cachyos.sh — make Limine auto-select and boot linux-cachyos.
#
# Fixes nested menus where the top "HyperWebster / hyperarch" row is only a
# directory: Enter expands it, but nothing is highlighted and timeout cannot
# boot a directory. Sets default_entry to the linux-cachyos leaf (path form)
# and expands the parent with /+ so the submenu opens with that kernel focused.
#
# Idempotent. REQUIRES ROOT. Soft-exits 0 when limine.conf is absent.
set -euo pipefail

ESP_PATH=/boot
DEFAULTS=/etc/default/limine

[ "$(id -u)" -eq 0 ] || { echo "must run as root" >&2; exit 1; }

if [ -f "$DEFAULTS" ]; then
  esp_line=$(grep -E '^ESP_PATH=' "$DEFAULTS" | head -1 || true)
  if [ -n "$esp_line" ]; then
    ESP_PATH=${esp_line#ESP_PATH=}
    ESP_PATH=${ESP_PATH#\"}
    ESP_PATH=${ESP_PATH%\"}
  fi
fi
[ -n "${ESP_PATH:-}" ] || ESP_PATH=/boot

CONF="$ESP_PATH/limine.conf"
[ -f "$CONF" ] || { echo "no $CONF — skipping (not a Limine install)"; exit 0; }

python3 - "$CONF" <<'PY'
import re, sys
from pathlib import Path

conf_path = Path(sys.argv[1])
text = conf_path.read_text()
lines = text.splitlines(keepends=True)

entry_re = re.compile(r"^(?P<slashes>/+)(?P<plus>\+?)(?P<title>.+?)\s*$")

entries = []  # {depth, title, line_idx, plus}
for i, line in enumerate(lines):
    m = entry_re.match(line.rstrip("\n"))
    if not m:
        continue
    depth = len(m.group("slashes"))
    entries.append({
        "depth": depth,
        "title": m.group("title"),
        "plus": bool(m.group("plus")),
        "line_idx": i,
        "slashes": m.group("slashes"),
    })

if not entries:
    print("no Limine menu entries — skipping")
    sys.exit(0)

def path_to(idx: int) -> str:
    """Build Limine default_entry path for entries[idx]."""
    target = entries[idx]
    chain = [target]
    need = target["depth"] - 1
    for j in range(idx - 1, -1, -1):
        if need <= 0:
            break
        e = entries[j]
        if e["depth"] == need:
            chain.append(e)
            need -= 1
    chain.reverse()

    def esc(name: str) -> str:
        return name.replace("\\", "\\\\").replace("/", "\\/").replace("#", "\\#")

    return "/".join(esc(e["title"]) for e in chain)

def score(title: str) -> tuple:
    t = title.lower()
    # Prefer real cachyos kernel rows; demote fallbacks / snapshots / starman.
    if "starman" in t or "snapshot" in t:
        return (100,)
    if "cachyos" in t and "fallback" not in t:
        return (0, len(t))
    if t in ("linux-cachyos", "linux cachyos"):
        return (0, 0)
    if "cachy" in t:
        return (1, len(t))
    if re.search(r"\blinux\b", t) and "fallback" not in t and "asahi" not in t:
        return (5, len(t))
    if "hyperwebster" in t or "hyperarch" in t:
        # Parent directories / UKI desktop — only if no better leaf
        return (20, len(t))
    return (50, len(t))

# Prefer a *leaf* (no following deeper child immediately under it).
def is_leaf(i: int) -> bool:
    d = entries[i]["depth"]
    if i + 1 < len(entries) and entries[i + 1]["depth"] > d:
        return False
    return True

candidates = [(score(entries[i]["title"]), i) for i in range(len(entries)) if is_leaf(i)]
candidates.sort()
best_i = candidates[0][1]
best_path = path_to(best_i)
best_title = entries[best_i]["title"]

# Expand all ancestors of the chosen leaf so the submenu is open.
expand_idxs = set()
need = entries[best_i]["depth"] - 1
for j in range(best_i - 1, -1, -1):
    if need <= 0:
        break
    if entries[j]["depth"] == need:
        expand_idxs.add(j)
        need -= 1

out = list(lines)

# Rewrite entry headers to add + on directories we want expanded.
for j in expand_idxs:
    e = entries[j]
    if e["plus"]:
        continue
    idx = e["line_idx"]
    out[idx] = f"{e['slashes']}+{e['title']}\n"

# Set / replace default_entry
default_line = f"default_entry: {best_path}\n"
replaced = False
for i, line in enumerate(out):
    if re.match(r"^default_entry:\s*", line, re.I):
        out[i] = default_line
        replaced = True
        break
if not replaced:
    # Insert after timeout if present, else at top.
    insert_at = 0
    for i, line in enumerate(out):
        if re.match(r"^timeout:\s*", line, re.I):
            insert_at = i + 1
            break
    out.insert(insert_at, default_line)

new_text = "".join(out)
if new_text != text:
    bak = conf_path.with_name(conf_path.name + ".bak.cachyos-default")
    if not bak.exists():
        bak.write_text(text)
    conf_path.write_text(new_text)
    print(f"Limine default_entry → {best_path!r} (selected {best_title!r})")
else:
    print(f"Limine already defaults to {best_path!r}")
PY

sync
echo "prefer-limine-cachyos: done"
