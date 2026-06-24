#!/bin/sh
# Migration: LUKS TPM2 enrollment helper + sd-encrypt hook migration.
set -eu
SRC="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
[ -d "$SRC/luks-tpm-unlock" ] || exit 0
sudo sh "$SRC/luks-tpm-unlock/install-luks-tpm-unlock.sh"
