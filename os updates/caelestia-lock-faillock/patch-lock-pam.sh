#!/bin/sh
# patch-lock-pam.sh — make the Caelestia lock screen use a faillock-free PAM
# service. Two parts, both idempotent:
#
#   1. DELIVER the faillock-free `caelestia` service into the directory the lock
#      actually reads — Quickshell.shellDir + "/assets/pam.d" — i.e.
#      /etc/xdg/quickshell/caelestia/assets/pam.d/caelestia. (Placing it in
#      /etc/pam.d/caelestia, which PamContext never reads, makes the lock
#      fall through to assets/pam.d/passwd — still faillock'd — and reject even
#      the correct password.)
#   2. REPOINT the lock's PamContext at it: config: "passwd" -> "caelestia".
#
# Runs as root (via the installer, or the pacman hook after every caelestia-shell
# upgrade, which restores the shell tree under /etc/xdg — so BOTH the asset file
# and the repoint must be re-applied here each time, or an upgrade drops them).
#
# Symptom (before this fix): the lock screen rejects the CORRECT password; only a
# reboot escapes. The stock lock authenticates via PamContext { config: "passwd",
# configDirectory: shellDir + "/assets/pam.d" } -> assets/pam.d/passwd, which
# calls pam_faillock; a few failed unlocks trip a temporary account lock that
# then refuses every attempt (right password included) until /run/faillock clears.
#
# TARGET (Pam.qml) is overridable for testing the change against a copy; the
# asset destination is derived from it (shellDir = TARGET/../../..).
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRC_PAM="$HERE/etc-pam.d-caelestia"           # the faillock-free service we ship

TARGET=${TARGET:-/etc/xdg/quickshell/caelestia/modules/lock/Pam.qml}

[ -f "$TARGET" ] || { echo "caelestia-shell lock not found at $TARGET — nothing to patch"; exit 0; }

# shellDir = the caelestia shell root = three levels up from modules/lock/Pam.qml.
SHELLDIR=$(CDPATH= cd -- "$(dirname -- "$TARGET")/../.." && pwd)
ASSETS_PAMD="$SHELLDIR/assets/pam.d"

# --- 1. deliver the faillock-free service where the lock reads it -------------
if [ -f "$SRC_PAM" ]; then
  install -d -m 0755 "$ASSETS_PAMD"
  install -m 0644 "$SRC_PAM" "$ASSETS_PAMD/caelestia"
  echo ":: installed $ASSETS_PAMD/caelestia (faillock-free lock auth)"
else
  echo "WARNING: source PAM service $SRC_PAM missing — cannot deliver the lock service." >&2
fi

# --- 2. repoint the lock's PamContext at it ----------------------------------
# Already pointed at our service?
if grep -q 'config:[[:space:]]*"caelestia"' "$TARGET"; then
  echo ":: Pam.qml already points at the caelestia lock service"
  exit 0
fi

# Only act if the stock "passwd" service is referenced.
if ! grep -q 'config:[[:space:]]*"passwd"' "$TARGET"; then
  echo "WARNING: Pam.qml does not reference config: \"passwd\" — upstream shape changed." >&2
  echo "         Leaving it untouched; review the lock PamContext for the new" >&2
  echo "         service name and update the regex in $(basename "$0")." >&2
  exit 0
fi

cp -n "$TARGET" "$TARGET.pre-hyperwebster" 2>/dev/null || true

# Repoint only the PAM service name; keep everything else as-is.
sed -i 's/config:\([[:space:]]*\)"passwd"/config:\1"caelestia"/g' "$TARGET"

if grep -q 'config:[[:space:]]*"caelestia"' "$TARGET"; then
  echo ":: patched $TARGET (lock now uses the faillock-free caelestia PAM service)"
else
  echo "WARNING: patch did not apply — Pam.qml left untouched." >&2
  exit 0
fi
