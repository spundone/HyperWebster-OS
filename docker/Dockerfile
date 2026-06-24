# Arch Linux image with ISO-builder dependencies for cross-platform builds.
# Built and run via scripts/build-in-container.sh (./build.sh on macOS).
FROM archlinux:latest

RUN pacman -Syu --noconfirm \
    && pacman -S --noconfirm --needed \
        git \
        libisoburn \
        squashfs-tools \
        coreutils \
        devtools \
        pacman-contrib \
        reflector \
        util-linux \
        sudo \
    && pacman -Scc --noconfirm

WORKDIR /build

# Container runs as root; hyperwebster.sh skips sudo when uid 0.
ENTRYPOINT ["/bin/bash", "-lc"]
