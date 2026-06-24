#!/bin/sh
# install-caelestia-lock-pam.sh — idempotent. REQUIRES ROOT.
#
# Thin wrapper kept for back-compat (older migrations / docs reference it).
# The real work — DELIVER the faillock-free PAM service into the directory the
# lock actually reads (shellDir/assets/pam.d/caelestia) AND repoint Pam.qml — is
# done by patch-lock-pam.sh, which is also what the caelestia-shell pacman hook
# runs after every upgrade. Delegating keeps a single source of truth and avoids
# the old F1 bug where this script wrote /etc/pam.d/caelestia (a path PamContext
# never reads), leaving the lock on the faillock'd assets/pam.d/passwd service.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ "$(id -u)" -ne 0 ]; then
  echo "must run as root" >&2
  exit 1
fi

exec sh "$HERE/patch-lock-pam.sh"
