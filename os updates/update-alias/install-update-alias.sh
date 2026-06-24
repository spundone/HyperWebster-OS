#!/bin/sh
# install-update-alias.sh — backward-compat symlinks for stale nosignal-* CLIs.
#
# Nexus QML (and older layer copies) may still invoke nosignal-update or
# nosignal-update-check. Point them at the real hyperwebster-* commands.
# Idempotent. Safe in chroot.
set -eu

HW_UPDATE=$(command -v hyperwebster-update 2>/dev/null \
  || echo "${HOME}/.local/share/hyperwebster/hyperwebster-update/bin/hyperwebster-update")
HW_CHECK=$(command -v hyperwebster-update-check 2>/dev/null \
  || echo "${HOME}/.local/bin/hyperwebster-update-check")

link_alias() {
  dest="$1"
  target="$2"
  mkdir -p "$(dirname -- "$dest")"
  ln -sf "$target" "$dest"
}

# User PATH (what Nexus QML hardcodes for update actions).
link_alias "${HOME}/.local/bin/nosignal-update" "$HW_UPDATE"
link_alias "${HOME}/.local/bin/nosignal-update-check" "$HW_CHECK"

# System-wide fallback for scripts referencing /usr/local/bin.
install_system() {
  mkdir -p /usr/local/bin
  link_alias /usr/local/bin/nosignal-update "$HW_UPDATE"
  link_alias /usr/local/bin/nosignal-update-check "$HW_CHECK"
}

if [ "$(id -u)" -eq 0 ]; then
  install_system
else
  sudo mkdir -p /usr/local/bin
  sudo ln -sf "$HW_UPDATE" /usr/local/bin/nosignal-update
  sudo ln -sf "$HW_CHECK" /usr/local/bin/nosignal-update-check
fi

# One-time migration: read cached status from the old nosignal state dir.
OLD="${XDG_STATE_HOME:-${HOME}/.local/state}/nosignal"
NEW="${XDG_STATE_HOME:-${HOME}/.local/state}/hyperwebster"
mkdir -p "$NEW"
for f in update-status.json applied; do
  if [ -f "$OLD/$f" ] && [ ! -f "$NEW/$f" ]; then
    cp -a "$OLD/$f" "$NEW/$f"
  fi
done

echo "update-alias: nosignal-update -> $HW_UPDATE"
