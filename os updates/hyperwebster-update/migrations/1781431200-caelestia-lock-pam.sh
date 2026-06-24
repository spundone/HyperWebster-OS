#!/usr/bin/env bash
# Migration: make the Caelestia lock faillock-free. patch-lock-pam.sh
# does both halves — delivers the faillock-free service into the dir the lock
# actually reads (shellDir/assets/pam.d/caelestia) and repoints Pam.qml
# ("passwd" -> "caelestia"). Idempotent; the pacman hook re-applies it after
# every caelestia-shell upgrade.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sudo sh "$HYPERWEBSTER_SRC/caelestia-lock-faillock/patch-lock-pam.sh" || true
