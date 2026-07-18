#!/bin/sh
# install-locale-utf8.sh — force a UTF-8 locale for Qt / caelestia / Hyprland.
# Fixes: Detected locale "en_US" with character encoding "ISO-8859-1".
# Idempotent.
set -eu

ENV_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d"
ENV_FILE="$ENV_DIR/99-hyperwebster-locale.conf"
LOCALE_CONF=/etc/locale.conf
LOCALE_GEN=/etc/locale.gen

# Prefer an existing LANG that already has .UTF-8; otherwise upgrade bare
# language tags (en_US → en_US.UTF-8) and fall back to en_US.UTF-8.
current=$(
  if [ -f "$LOCALE_CONF" ]; then
    sed -n 's/^LANG=//p' "$LOCALE_CONF" | head -1 | tr -d '"' | tr -d "'"
  fi
)
current=${current:-${LANG:-}}
case "$current" in
  *.UTF-8|*.utf8|*.UTF8) target="$current" ;;
  ""|C|POSIX) target="en_US.UTF-8" ;;
  *) target="${current}.UTF-8" ;;
esac
# Normalise lowercase utf8 → UTF-8 for locale.gen matching.
case "$target" in
  *.utf8) target="${target%.utf8}.UTF-8" ;;
  *.UTF8) target="${target%.UTF8}.UTF-8" ;;
esac

echo ":: target UTF-8 locale: $target"

# 1. Enable in locale.gen (system).
if [ -f "$LOCALE_GEN" ]; then
  sudo sed -i \
    -e "s|^#${target} UTF-8|${target} UTF-8|" \
    -e "s|^#${target} utf8|${target} UTF-8|" \
    "$LOCALE_GEN"
  if ! grep -qE "^${target}[[:space:]]+UTF-8" "$LOCALE_GEN" 2>/dev/null; then
    printf '%s UTF-8\n' "$target" | sudo tee -a "$LOCALE_GEN" >/dev/null
  fi
  # Always keep en_US.UTF-8 available as a fallback.
  sudo sed -i 's|^#en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|' "$LOCALE_GEN"
  sudo locale-gen >/dev/null
  echo ":: locale-gen refreshed"
fi

# 2. System locale.conf
tmp=$(mktemp)
{
  echo "LANG=$target"
  if [ -f "$LOCALE_CONF" ]; then
    # Keep non-LANG lines (LC_* overrides) but drop stale LANG=.
    grep -vE '^LANG=' "$LOCALE_CONF" || true
  fi
} > "$tmp"
sudo install -m 0644 "$tmp" "$LOCALE_CONF"
rm -f "$tmp"
echo ":: wrote $LOCALE_CONF (LANG=$target)"

# 3. User session env (picked up by systemd --user / uwsm / graphical session).
mkdir -p "$ENV_DIR"
cat > "$ENV_FILE" <<EOF
# HyperWebster: Qt / Quickshell require a UTF-8 locale.
LANG=$target
LC_CTYPE=$target
EOF
echo ":: wrote $ENV_FILE"

# Apply for this shell too (best-effort; new sessions pick up environment.d).
export LANG="$target"
export LC_CTYPE="$target"

echo "Done. Log out/in (or reboot) so the graphical session picks up LANG=$target."
echo "Quick check: locale | head -5"
