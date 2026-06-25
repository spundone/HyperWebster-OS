#!/usr/bin/env bash
# pull-layer.sh — refresh ~/.local/share/hyperwebster from the public GitHub repo.
# Safe to run standalone or from hyperwebster-update. Preserves migration state
# (~/.local/state/hyperwebster/applied).
set -euo pipefail

DEST="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyperwebster"
VERSION_FILE="$STATE_DIR/layer-version"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/hyperwebster/layer-source.conf"
LAYER_URL="${HYPERWEBSTER_LAYER_URL:-https://github.com/spundone/HyperWebster-OS/archive/refs/heads/main.tar.gz}"

[ -f "$CONFIG" ] && . "$CONFIG"

log() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m::\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

for cmd in curl tar; do
  command -v "$cmd" >/dev/null 2>&1 || die "$cmd is required to pull the HyperWebster layer"
done

tmpdir=$(mktemp -d)
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

log "fetching layer from ${LAYER_URL##*//}"
curl -fSL --proto '=https' --tlsv1.2 --retry 3 --retry-delay 2 \
  -o "$tmpdir/layer.tar.gz" "$LAYER_URL" \
  || die "failed to download layer (check network and HYPERWEBSTER_LAYER_URL)"

tar -xzf "$tmpdir/layer.tar.gz" -C "$tmpdir"
top=$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -1)
[ -n "${top:-}" ] || die "unexpected tarball layout (no top-level directory)"
src="$top/os updates"
[ -d "$src" ] || die "tarball missing 'os updates/' (wrong URL or repo layout?)"

mkdir -p "$DEST" "$STATE_DIR"
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete "$src/" "$DEST/"
else
  warn "rsync not found — merging with cp (orphan files may remain)"
  cp -a "$src/." "$DEST/"
fi

chmod +x "$DEST/hyperwebster-update/bin/hyperwebster-update" \
  "$DEST/hyperwebster-update/bin/pull-layer.sh" \
  "$DEST/hyperwebster-update/migrations/"*.sh 2>/dev/null || true

# Keep PATH symlink current after refresh.
mkdir -p "$HOME/.local/bin"
ln -sf "$DEST/hyperwebster-update/bin/hyperwebster-update" "$HOME/.local/bin/hyperwebster-update"
ln -sf "$DEST/hyperwebster-update/bin/pull-layer.sh" "$HOME/.local/bin/hyperwebster-layer-pull"

commit=""
if command -v curl >/dev/null 2>&1; then
  commit=$(curl -fsSL --proto '=https' --tlsv1.2 --max-time 15 \
    https://api.github.com/repos/spundone/HyperWebster-OS/commits/main \
    | sed -n 's/^[[:space:]]*"sha":[[:space:]]*"\([0-9a-f]\{7,40\}\)".*/\1/p' \
    | head -1) || true
fi

fetched=$(date -Is)
{
  echo "fetched_at=$fetched"
  echo "url=$LAYER_URL"
  [ -n "$commit" ] && echo "commit=$commit"
  mig=$(find "$DEST/hyperwebster-update/migrations" -maxdepth 1 -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
  echo "migrations=$mig"
} > "$VERSION_FILE"

if [ -n "$commit" ]; then
  log "layer refreshed (${commit:0:7}, $mig migrations in tree)"
else
  log "layer refreshed ($mig migrations in tree)"
fi
