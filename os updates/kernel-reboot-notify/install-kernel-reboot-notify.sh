#!/bin/sh
# install-kernel-reboot-notify.sh — idempotent.
#
# After a kernel update nothing tells the user to reboot. The new
# kernel + modules are on disk but the old kernel keeps running with its modules
# dir removed (can't load fresh modules), and the new UKI isn't booted. Installs:
#   1. hyperwebster-reboot-check  -> ~/.local/bin            (helper + desktop notify)
#   2. 95-hyperwebster-kernel-reboot.hook -> /etc/pacman.d/hooks (root; terminal warn)
#   3. a call to hyperwebster-reboot-check at the end of hyperwebster-update (idempotent)
#
# Re-runnable. The pacman-hook step needs root; if not root, it is skipped with a
# notice (run once as root, or let the builder ship the hook in the ISO).
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# 1. helper
install -m 0755 "$HERE/hyperwebster-reboot-check" "$BIN_DIR/hyperwebster-reboot-check"
echo "installed $BIN_DIR/hyperwebster-reboot-check"

# 2. pacman hook (root)
HOOK_DST=/etc/pacman.d/hooks/95-hyperwebster-kernel-reboot.hook
if [ "$(id -u)" -eq 0 ]; then
  install -Dm 0644 "$HERE/95-hyperwebster-kernel-reboot.hook" "$HOOK_DST"
  echo "installed $HOOK_DST"
elif command -v sudo >/dev/null 2>&1; then
  sudo install -Dm 0644 "$HERE/95-hyperwebster-kernel-reboot.hook" "$HOOK_DST" \
    && echo "installed $HOOK_DST (via sudo)" \
    || echo "WARN: could not install pacman hook (need root) — skipped"
else
  echo "WARN: not root and no sudo — pacman hook NOT installed ($HOOK_DST)"
fi

# 3. wire into hyperwebster-update (idempotent; edits the real file behind the symlink)
NU=$(command -v hyperwebster-update 2>/dev/null || echo "$BIN_DIR/hyperwebster-update")
NU=$(readlink -f -- "$NU" 2>/dev/null || echo "$NU")
MARKER="# >>> hyperwebster kernel-reboot-notify >>>"
if [ -f "$NU" ] && ! grep -qF "$MARKER" "$NU"; then
  # insert the call just before the final 'HyperWebster up to date' log line
  tmp=$(mktemp)
  awk -v marker="$MARKER" '
    /log "HyperWebster up to date"/ && !done {
      print marker
      print "command -v hyperwebster-reboot-check >/dev/null 2>&1 && hyperwebster-reboot-check || true"
      print "# <<< hyperwebster kernel-reboot-notify <<<"
      done=1
    }
    { print }
  ' "$NU" > "$tmp" && cat "$tmp" > "$NU" && rm -f "$tmp"
  echo "wired hyperwebster-reboot-check into $NU"
else
  echo "hyperwebster-update already wired (or not found at $NU) — skipped"
fi

echo "kernel-reboot-notify: ok"
