#!/usr/bin/env bash
# 1781467200-cachy-pacman-db-pin.sh
# Follow-up to 1781460000-cachyos-repo-switch: makes the
# stock-pacman pin DURABLE (IgnorePkg = pacman in pacman.conf for as long as
# CachyOS is enabled, not just the helper's own -Suu) and cleans the
# `%INSTALLED_DB%` field the CachyOS pacman leaves in the local DB (a warning
# flood on every pacman/yay op). The fix folds INTO the existing
# cachyos-repo-switch component: it ships the corrected hyperwebster-cachy-repo plus
# the standalone hyperwebster-cachy-db-clean repair tool, and its installer
# one-shot-cleans any contamination already present. Re-running the component
# installer here picks all of that up. Idempotent.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sudo env HYPERWEBSTER_SKIP_SHELL_PATCH=1 sh "$HYPERWEBSTER_SRC/cachyos-repo-switch/install-cachyos-repo-switch.sh"
