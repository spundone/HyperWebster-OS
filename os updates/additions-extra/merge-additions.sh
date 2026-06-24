#!/bin/sh
# merge-additions.sh — idempotent. User-level (no root).
#
# Adds this component's additions.json items (by id) into the installed
# Settings -> Additions manifest, skipping ones already present. For the ISO the
# builder should instead ship this additions.json as the canonical manifest.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
LIVE="$HERE/../additions-installer/additions.json"
SRC="$HERE/additions.json"
[ -f "$LIVE" ] || { echo "live additions.json not found at $LIVE" >&2; exit 1; }
[ -f "$SRC" ]  || { echo "component additions.json missing" >&2; exit 1; }
cp -a "$LIVE" "$LIVE.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
python3 - "$LIVE" "$SRC" <<'PY'
import json,sys
live_p,src_p=sys.argv[1:3]
live=json.load(open(live_p)); src=json.load(open(src_p))
have={i["id"] for i in live["items"]}
added=[i for i in src["items"] if i["id"] not in have]
live["items"].extend(added)
json.dump(live,open(live_p,"w"),indent=2,ensure_ascii=False); open(live_p,"a").write("\n")
print("merged:", ", ".join(i["id"] for i in added) if added else "(none new)")
print("total items:", len(live["items"]))
PY
echo "additions-extra: ok"
