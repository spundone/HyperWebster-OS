#!/usr/bin/env bash
# Migration: convert the installer-seeded protocol:linux Limine entry to a
# protocol:efi UKI entry so the default auto-boot target survives a kernel
# update. Idempotent — delegates to the root repair.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sudo sh "$HYPERWEBSTER_SRC/limine-uki-dead-entry/fix-limine-uki-entry.sh"
