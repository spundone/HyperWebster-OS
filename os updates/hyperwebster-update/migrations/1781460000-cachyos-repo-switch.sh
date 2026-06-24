#!/usr/bin/env bash
# 1781460000-cachyos-repo-switch.sh
# Delegates to the CachyOS repo + kernel switch installer (Settings -> Services
# toggle "CachyOS repositories"). Installs the CLI, the validated sudoers
# drop-in, and the panel toggle. Does NOT enable the CachyOS repos — that's a
# deliberate user action (heavy, networked, reboots the kernel). Idempotent.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sudo sh "$HYPERWEBSTER_SRC/cachyos-repo-switch/install-cachyos-repo-switch.sh"
