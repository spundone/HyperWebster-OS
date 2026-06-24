#!/usr/bin/env bash
#
# Run hyperwebster.sh inside an Arch Linux container with the repo bind-mounted.
# Requires Docker or Podman. Used by ./build.sh on macOS and non-Arch Linux.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE_NAME="${HYPERWEBSTER_BUILD_IMAGE:-hyperwebster-builder:latest}"
DOCKERFILE="$SCRIPT_DIR/docker/Dockerfile"

container_runtime() {
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    echo docker
    return 0
  fi
  if command -v podman >/dev/null 2>&1 && podman info >/dev/null 2>&1; then
    echo podman
    return 0
  fi
  echo "ERROR: Docker or Podman is required for container builds." >&2
  echo "       Install Docker Desktop on macOS: https://docs.docker.com/desktop/" >&2
  exit 1
}

find_stock_iso() {
  if [ -n "${HYPERWEBSTER_ARCH_ISO:-}" ] && [ -f "$HYPERWEBSTER_ARCH_ISO" ]; then
    echo "$HYPERWEBSTER_ARCH_ISO"
    return 0
  fi
  local iso
  shopt -s nullglob
  for iso in "$SCRIPT_DIR"/archlinux-*.iso; do
    [[ "$(basename "$iso")" == *HyperWebster* ]] && continue
    echo "$iso"
    return 0
  done
  shopt -u nullglob
  return 1
}

RUNTIME="$(container_runtime)"

echo "==> Using container runtime: $RUNTIME"
echo "==> Building image $IMAGE_NAME (if needed)..."
"$RUNTIME" build -t "$IMAGE_NAME" -f "$DOCKERFILE" "$SCRIPT_DIR/docker"

if ! find_stock_iso >/dev/null; then
  echo "ERROR: No stock Arch ISO found in $SCRIPT_DIR" >&2
  echo >&2
  echo "Download the latest Arch ISO and place it in the repo root:" >&2
  echo "  curl -LO https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso" >&2
  echo >&2
  echo "Or set HYPERWEBSTER_ARCH_ISO=/path/to/archlinux-x86_64.iso" >&2
  exit 1
fi

BUILD_UID="$(id -u)"
BUILD_GID="$(id -g)"
BUILD_USER="$(id -un)"

# mkarchroot needs mount namespaces; --privileged is the most reliable path
# across Docker Desktop (macOS) and Linux.
CONTAINER_ARGS=(
  run --rm -it
  --privileged
  --cap-add SYS_ADMIN
  --security-opt seccomp=unconfined
  -v "$SCRIPT_DIR:/build"
  -w /build
  -e HYPERWEBSTER_BUILD_UID="$BUILD_UID"
  -e HYPERWEBSTER_BUILD_GID="$BUILD_GID"
  -e HYPERWEBSTER_BUILD_USER="$BUILD_USER"
)

if [ -n "${HYPERWEBSTER_ARCH_ISO:-}" ]; then
  iso_basename="$(basename "$HYPERWEBSTER_ARCH_ISO")"
  CONTAINER_ARGS+=(-e "HYPERWEBSTER_ARCH_ISO=/build/$iso_basename")
  if [[ "$HYPERWEBSTER_ARCH_ISO" != "$SCRIPT_DIR/"* ]]; then
    CONTAINER_ARGS+=(-v "$HYPERWEBSTER_ARCH_ISO:/build/$iso_basename:ro")
  fi
fi

if [ -n "${SSH_PUBKEY:-}" ]; then
  CONTAINER_ARGS+=(-e "SSH_PUBKEY=$SSH_PUBKEY")
fi
if [ -n "${HYPERWEBSTER_MIRRORLIST:-}" ]; then
  CONTAINER_ARGS+=(-v "$HYPERWEBSTER_MIRRORLIST:/build/.mirrorlist:ro")
  CONTAINER_ARGS+=(-e "HYPERWEBSTER_MIRRORLIST=/build/.mirrorlist")
fi
if [ -n "${HYPERWEBSTER_REFRESH_MIRRORS:-}" ]; then
  CONTAINER_ARGS+=(-e "HYPERWEBSTER_REFRESH_MIRRORS=$HYPERWEBSTER_REFRESH_MIRRORS")
fi

echo "==> Starting ISO build in Arch container (this takes a while)..."
exec "$RUNTIME" "${CONTAINER_ARGS[@]}" "$IMAGE_NAME" ./hyperwebster.sh "$@"
