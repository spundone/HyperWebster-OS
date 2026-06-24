#!/usr/bin/env bash
# Migration: Omarchy-inspired utility workflows (share, transcode, OCR, night light).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/omarchy-extras/install-omarchy-extras.sh"
if ! pacman -Qq tesseract >/dev/null 2>&1 || ! pacman -Qq imagemagick >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm tesseract imagemagick \
    || echo "WARNING: install tesseract + imagemagick for OCR/transcode" >&2
fi
