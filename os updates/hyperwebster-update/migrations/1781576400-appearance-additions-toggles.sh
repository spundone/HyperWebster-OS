#!/usr/bin/env bash
# Migration: appearance toggles, blur default-on, Additions layer-mod toggles manifest.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"

# Install rounding toggle + refresh blur CLI (rounding decoupled from blur).
sh "$HYPERWEBSTER_SRC/appearance-toggles/install-appearance-toggles.sh"
sh "$HYPERWEBSTER_SRC/blur-toggle/install-blur-toggle.sh"

# Refresh layer toggle CLIs shipped with their components.
for comp in hypersmooth-display tv-gaming-display launcher-raycast omarchy-extras; do
  [ -f "$HYPERWEBSTER_SRC/$comp/install-${comp}.sh" ] && \
    sh "$HYPERWEBSTER_SRC/$comp/install-${comp}.sh" 2>/dev/null || true
done

# Default blur ON for boxes that never chose (no state file yet).
STATE="${HOME}/.local/state/hyperwebster/blur-enabled"
if [ ! -f "$STATE" ]; then
  hyperwebster-blur-toggle enable >/dev/null 2>&1 || true
fi

# Ship updated Additions manifest + QML (skip shell patch — branding hook reapplies).
env HYPERWEBSTER_SKIP_SHELL_PATCH=1 sh "$HYPERWEBSTER_SRC/additions-installer/install-additions-installer.sh"
"$HOME/.local/bin/hyperwebster-additions" status >/dev/null 2>&1 || true

# Re-apply Additions page patch after manifest/QML update.
if [ -z "${HYPERWEBSTER_SKIP_SHELL_PATCH:-}" ]; then
  sudo sh "$HOME/.local/share/hyperwebster/additions-installer/patch-additions-page.sh" \
    2>/dev/null || sudo sh "$HYPERWEBSTER_SRC/additions-installer/patch-additions-page.sh" \
    2>/dev/null || true
fi

echo "appearance-additions-toggles: blur/rounding CLIs + Additions toggles updated"
