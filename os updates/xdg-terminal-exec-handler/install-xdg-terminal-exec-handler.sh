#!/bin/sh
# install-xdg-terminal-exec-handler.sh — idempotent.
#
# Symptom : critical notification "app2unit: Error — Executable not found:
#           'xdg-terminal-exec'", and any Terminal=true desktop entry (or
#           `app2unit -T`) fails to launch.
# Cause   : app2unit's terminal handler is hardcoded to
#           A2U__TERMINAL_HANDLER=xdg-terminal-exec, but HyperWebster never shipped
#           that binary, and no ~/.config/xdg-terminals.list exists.
# Fix     : (preferred, builder) add the real `xdg-terminal-exec` package to the
#           ISO package set + ship a system xdg-terminals.list.
#           (offline fallback, this script) install a small shim on PATH that
#           launches the configured terminal, and seed xdg-terminals.list.
#
# Idempotent: safe to re-run. Self-corrects: if a real xdg-terminal-exec lands
# in a system bin, the user-level shim is removed so it stops shadowing it.
set -eu

USER_HOME="${HOME:?}"
BIN_DIR="$USER_HOME/.local/bin"
SHIM="$BIN_DIR/xdg-terminal-exec"
TERMLIST="${XDG_CONFIG_HOME:-$USER_HOME/.config}/xdg-terminals.list"
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

mkdir -p "$BIN_DIR"

# Is there a REAL xdg-terminal-exec somewhere outside our shim location?
real=""
for p in /usr/bin/xdg-terminal-exec /usr/local/bin/xdg-terminal-exec; do
  [ -x "$p" ] && real="$p" && break
done

if [ -n "$real" ]; then
  # Real package present — remove our shim so it doesn't shadow it via PATH.
  if [ -e "$SHIM" ] && grep -q 'xdg-terminal-exec — offline shim (HyperWebster)' "$SHIM" 2>/dev/null; then
    rm -f "$SHIM"
    echo "real xdg-terminal-exec at $real — removed HyperWebster shim"
  fi
else
  # No real binary — install/refresh the shim from the bundled copy.
  install -m 0755 "$HERE/xdg-terminal-exec" "$SHIM"
  echo "installed shim -> $SHIM"
fi

# Seed the default-terminal hint (don't clobber a user edit).
if [ ! -e "$TERMLIST" ]; then
  printf 'kitty.desktop\n' > "$TERMLIST"
  echo "wrote $TERMLIST (kitty.desktop)"
fi

echo "xdg-terminal-exec-handler: ok"
