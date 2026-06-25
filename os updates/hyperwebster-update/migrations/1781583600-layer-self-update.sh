#!/usr/bin/env bash
# Migration: bootstrap on-box layer self-update (GitHub pull before migrations).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hyperwebster"
mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_DIR/layer-source.conf" ]; then
  cat > "$CONFIG_DIR/layer-source.conf" <<'EOF'
# HyperWebster layer pull source (used by hyperwebster-update / pull-layer.sh)
HYPERWEBSTER_LAYER_URL=https://github.com/spundone/HyperWebster-OS/archive/refs/heads/main.tar.gz
EOF
fi

mkdir -p "$HOME/.local/bin"
ln -sf "$HYPERWEBSTER_SRC/hyperwebster-update/bin/hyperwebster-update" \
  "$HOME/.local/bin/hyperwebster-update"
ln -sf "$HYPERWEBSTER_SRC/hyperwebster-update/bin/pull-layer.sh" \
  "$HOME/.local/bin/hyperwebster-layer-pull"
chmod +x "$HYPERWEBSTER_SRC/hyperwebster-update/bin/pull-layer.sh"
