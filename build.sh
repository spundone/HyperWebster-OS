#!/usr/bin/env bash
#
# build.sh — cross-platform entry point for the HyperWebster ISO builder.
#
# On Arch Linux with devtools installed: runs ./hyperwebster.sh directly.
# On macOS or non-Arch Linux: runs the build inside an Arch container
# (Docker or Podman) via scripts/build-in-container.sh.
#
# Usage:
#   ./build.sh [hyperwebster.sh args...]
#
# Environment (forwarded to hyperwebster.sh where applicable):
#   HYPERWEBSTER_ARCH_ISO, SSH_PUBKEY, HYPERWEBSTER_MIRRORLIST,
#   HYPERWEBSTER_REFRESH_MIRRORS, HYPERWEBSTER_FORCE_CONTAINER=1
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER_SCRIPT="$SCRIPT_DIR/scripts/build-in-container.sh"

hyperwebster_native_ready() {
  command -v pacman >/dev/null 2>&1 \
    && command -v mkarchroot >/dev/null 2>&1 \
    && command -v xorriso >/dev/null 2>&1 \
    && command -v unsquashfs >/dev/null 2>&1
}

container_runtime() {
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    echo docker
    return 0
  fi
  if command -v podman >/dev/null 2>&1 && podman info >/dev/null 2>&1; then
    echo podman
    return 0
  fi
  return 1
}

usage_container_hint() {
  cat >&2 <<'EOF'

HyperWebster ISO builds require Arch Linux tooling (pacman, devtools, xorriso).

On macOS or non-Arch Linux, install Docker Desktop (or Podman) and retry:
  https://docs.docker.com/desktop/setup/install/mac-install/

On Arch Linux, install build dependencies and run ./hyperwebster.sh directly:
  sudo pacman -S --needed git libisoburn squashfs-tools coreutils devtools \
    pacman-contrib reflector util-linux

Or force a container build on any host:
  HYPERWEBSTER_FORCE_CONTAINER=1 ./build.sh
EOF
}

if [ "${HYPERWEBSTER_FORCE_CONTAINER:-0}" = "1" ]; then
  exec "$CONTAINER_SCRIPT" "$@"
fi

if hyperwebster_native_ready; then
  exec "$SCRIPT_DIR/hyperwebster.sh" "$@"
fi

if container_runtime >/dev/null; then
  exec "$CONTAINER_SCRIPT" "$@"
fi

echo "ERROR: No suitable build environment found." >&2
usage_container_hint
exit 1
