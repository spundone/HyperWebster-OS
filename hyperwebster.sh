#!/usr/bin/env bash
#
# hyperwebster.sh — one script: turn a stock Arch ISO into a graphical Arch desktop
# installer ISO. The installed system boots into SDDM (themed to match the
# desktop — layer changes 16+19; was greetd+tuigreet) and runs Hyprland,
# themed with the caelestia dotfiles
# (https://github.com/caelestia-dots/caelestia).
#
# Architecture (Phase 3 — FULLY OFFLINE): the ISO bundles EVERYTHING needed
# for the install. At build time, this script:
#   * builds the caelestia AUR packages (shell/CLI/meta + quickshell-git and
#     friends) in a devtools clean chroot on the build host,
#   * downloads the complete pacstrap dependency tree (including every GPU
#     driver variant, the CachyOS linux-cachyos kernel + trust packages, and
#     the prebuilt Limine snapshot tools from the omarchy repo) into a local
#   * vendors the caelestia dotfiles + quickshell-overview as pinned tarballs,
# and places all of it on the ISO9660 (outside the squashfs, visible to the
# live environment at /run/archiso/bootmnt/hyperwebster). The installer pacstraps
# entirely from that file:// repo and lays down the whole desktop — dotfiles,
# theming, workspace overview, Btrfs+Limine snapshots — at INSTALL TIME in the
# chroot. No network is needed at install or on first boot: the machine boots
# straight into the themed SDDM greeter and a fully themed desktop. (The old
# first-boot build stage — paru bootstrap, nmtui gate, tty1 autologin — is gone.)
#
# Network IS needed on the BUILD host (AUR builds + repo download), and the
# Wi-Fi prompt remains in the installer as an OPTIONAL step purely so the
# credentials can be persisted into the installed system.
#
# NOTE: this is the *ISO builder*. It bundles and installs the upstream
# caelestia dotfiles; it is not affiliated with that project.
#
# Usage:
#   1. Drop a stock Arch ISO (https://archlinux.org/download/, file starts
#      with 'archlinux-') into the same folder as this script.
#   2. ./hyperwebster.sh
#   3. Output: hyperwebster-arch-YYYYMMDD.iso (Ventoy-compatible, dd-bootable).
#
# The offline payload is cached in ./offline/ — subsequent builds reuse the
# built AUR packages and previously downloaded repo packages. Delete that
# folder (or individual .built-* stamps in offline/aur/) to force a rebuild.
#
# Dependencies (build host): xorriso, squashfs-tools, git, sha512sum, sudo,
# devtools (mkarchroot/makechrootpkg), pacman-contrib (paccache).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK="$SCRIPT_DIR/work"
OFFLINE="$SCRIPT_DIR/offline"
INVOKING_USER="${SUDO_USER:-$(id -un)}"
INVOKING_GROUP="$(id -gn "$INVOKING_USER")"
OUT_ISO="$SCRIPT_DIR/hyperwebster-arch-$(date +%Y%m%d).iso"

# ---------------------------------------------------------------- pins ------
# The validated combination (VM-certified): caelestia dotfiles + the AUR
# release PKGBUILDs current at that commit, quickshell pinned to the commit
# the shell was validated against, and the overview sidecar pin.
CAELESTIA_DOTS_REPO="https://github.com/caelestia-dots/caelestia.git"
CAELESTIA_DOTS_COMMIT="757b7f26b8e637754ddd498671360dd6ba7e89ef"
OVERVIEW_REPO="https://github.com/Shanu-Kumawat/quickshell-overview.git"
OVERVIEW_COMMIT="74918ba66e0714017a6a5bfb9bf2affa66dabbc1"
QUICKSHELL_GIT_COMMIT="b66495f"   # short hash is fine for makepkg #commit=
# HyperWebster's fork of the caelestia shell — we BUILD this instead of the upstream
# caelestia-shell so the interface/layout is under our control and never gets
# overwritten by an upstream update (the package provides/conflicts caelestia-shell
# and is pinned here, so pacman/yay never replaces it). Updates are deliberate:
# advance the fork's `hyperwebster` branch, bump the pin, rebuild. The fork's
# packaging/PKGBUILD builds the shell from this exact commit.
# TODO: fork to your own hyperwebster-shell repo when ready to customize the shell.
HYPERWEBSTER_SHELL_REPO="https://github.com/28allday/nosignal-shell.git"
HYPERWEBSTER_SHELL_COMMIT="0ae859311310661555dae089c91f2c0bfaaec10b"
# OS theme wallpapers — the user's own Moebius-style generated art (11 pieces,
# 2944x1648, repo-local in assets/wallpapers/; replaced the third-party Last
# Horizon set 2026-06-11, which also clears the redistribution-rights concern).
# The desktop palette is generated FROM the default wallpaper by caelestia's
# dynamic Material scheme at install time.
WALLPAPERS_DIR="$SCRIPT_DIR/assets/wallpapers"
# foam-sea since change 18 (was wanderer.png). Build-time default only — no
# migration, so existing installs keep whatever the user picked.
DEFAULT_WALLPAPER="foam-sea.png"
# omarchy-send release binary (LocalSend-compatible LAN file transfer TUI).
OMARCHY_SEND_REPO="28allday/omarchy-send"
OMARCHY_SEND_VERSION="v0.1.11"
# HyperWebster layer — the "os updates" round developed and live-tested on real
# hardware (keybind cheatsheet, bash default shell, hyperwebster-update, yay+Shelly
# store, Omarchy keybindings, omadots polish, hyprmoncfg, settings Updates
# page, system polish). The tree is vendored verbatim onto the ISO and baked
# into ~/.local/share/hyperwebster at install time. Dev-only docs (changelog,
# builder/test notes) are kept unshipped in the repo's dev-docs/ folder.
HYPERWEBSTER_LAYER_DIR="$SCRIPT_DIR/os updates"
# LazyVim starter (omadots' nvim setup, change 6) — pinned, .git stripped.
LAZYVIM_REPO="https://github.com/LazyVim/starter"
LAZYVIM_COMMIT="803bc181d7c0d6d5eeba9274d9be49b287294d99"
# Flathub remote definition (change 4). The .flatpakrepo file embeds the GPG
# key, so `flatpak remote-add` from it works OFFLINE in the install chroot.
FLATHUB_REPO_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"

# ----------------------------------------------------- package manifests ----
# BASE_PKGS is the single source of truth for the non-GPU pacstrap set: it is
# written to the ISO as /hyperwebster/base-packages.list and read back by the
# installer (so the download closure and the installed set can never drift).
BASE_PKGS=(
  base linux linux-cachyos linux-cachyos-headers linux-firmware
  cachyos-keyring cachyos-mirrorlist cachyos-v3-mirrorlist cachyos-v4-mirrorlist
  intel-ucode amd-ucode cryptsetup tpm2-tss tpm2-tools
  networkmanager openssh sudo git curl wget vim less base-devel
  limine efibootmgr zram-generator
  btrfs-progs btrfsmaintenance snapper snap-pac btrfs-assistant-git
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
  polkit hyprpolkitagent qt5-wayland qt6-wayland xdg-user-dirs xdg-utils
  hyprland uwsm xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  hyprpicker hyprlock hypridle hyprsunset wl-clipboard cliphist inotify-tools
  grim slurp swappy brightnessctl playerctl pavucontrol
  # omarchy-extras: OCR + picture transcode (ffmpeg already via cliamp)
  tesseract imagemagick
  # Display manager: SDDM (layer change 16 — DeckShift's desktop<->gaming
  # session switching rewrites SDDM config; greetd/tuigreet couldn't do this).
  # xorg-server is for SDDM's X11 GREETER only (DisplayServer=x11, the
  # reliable path) — the Hyprland session itself stays Wayland.
  sddm xorg-server plymouth
  # NB: fish must STAY even though bash is the default shell (HyperWebster layer
  # change 2) — caelestia-meta hard-depends on it. foot stays as a meta dep
  # too (its menu entries are hidden by the layer's system-polish change).
  foot fish fastfetch starship btop jq eza trash-cli
  adw-gtk-theme papirus-icon-theme gnome-themes-extra ttf-jetbrains-mono-nerd
  ttf-material-symbols-variable ttf-cascadia-code-nerd
  noto-fonts noto-fonts-emoji
  kitty-terminfo foot-terminfo
  ufw
  caelestia-meta
  # default terminal (foot stays as caelestia-themed fallback)
  kitty
  # everyday apps
  chromium nautilus gvfs gvfs-mtp
  mpv imv papers gnome-calculator gnome-text-editor
  libreoffice-fresh ntfs-3g exfatprogs
  # default music player (layer change 24): CLIAmp, prebuilt in [omarchy]
  # (no AUR build); pulls ffmpeg + yt-dlp into the closure
  cliamp
  # monitor layout/profiles TUI + hotplug daemon (writes the same
  # ~/.config/hypr/monitors.conf the base config sources; superseded
  # nwg-displays — keep a SINGLE writer of that file). AUR-built.
  hyprmoncfg
  # software installation story: yay (AUR helper, also used by
  # hyperwebster-update) + Shelly GUI store (both AUR-built) + flatpak backend
  flatpak archlinux-appstream-data
  yay-bin shelly-bin
  # HyperWebster layer tooling: checkupdates (updates panel), desktop notify,
  # lspci for the Additions page's GPU-detected OBS encoders (change 25 —
  # present on the test boxes only as an incidental dep; make it explicit)
  pacman-contrib libnotify pciutils
  # omadots developer polish (starship/btop/eza already above)
  tmux neovim fzf bat zoxide
  # base default dev tooling (layer change 33): GitHub CLI (`gh`)
  github-cli
  # bluetooth
  bluez bluez-utils blueman
  # laptop: audio firmware + power profiles
  sof-firmware power-profiles-daemon
  # printing + network discovery
  cups system-config-printer avahi nss-mdns
  # GUI Wi-Fi fallback (non-CLI escape hatch beside the bar's Wi-Fi panel) +
  # GL/Vulkan info tools so `prime-run glxinfo`/`vulkaninfo` work for verifying
  # hybrid-GPU offload (hardware-test gap, 2026-06-20)
  nm-connection-editor mesa-utils vulkan-tools wlr-randr
  # mesh VPN (daemon enabled at install; user runs `sudo tailscale up` to auth)
  tailscale
  # CachyOS kernel variant picker (GUI) — pairs with linux-cachyos OOB default
  cachyos-kernel-manager
)

# Every GPU driver variant goes into the offline repo; the installer detects
# the hardware and installs only the matching subset. KEEP IN SYNC with the
# GPU detection block inside write_installer below.
GPU_ALL_PKGS=(
  mesa vulkan-icd-loader
  nvidia-open-dkms nvidia-utils egl-wayland libva-nvidia-driver
  nvidia-settings linux-headers
  nvidia-prime                       # prime-run offload (hybrid laptops)
  vulkan-radeon
  vulkan-intel intel-media-driver
  qemu-guest-agent spice-vdagent
  vulkan-swrast
)

# Prebuilt binaries from the omarchy repo (skips their GraalVM AUR build).
LIMINE_TOOLS=(limine-snapper-sync limine-mkinitcpio-hook)

# CachyOS kernel + trust/mirror packages — vendored into the offline repo at
# ISO build time (see build_offline_payload). linux stays as a Limine fallback.
CACHYOS_TARBALL_URL="https://mirror.cachyos.org/cachyos-repo.tar.xz"

# AUR packages built in the clean chroot, in dependency order (each build can
# resolve the previously built ones through the local bootstrap repo).
# caelestia-meta is NOT here — it builds from the dotfiles clone on the host.
AUR_BUILD_ORDER=(
  app2unit libcava python-materialyoucolor ttf-rubik-vf qtengine
  quickshell-git caelestia-cli nosignal-shell
  # HyperWebster layer round — independent of the caelestia chain (yay-bin and
  # shelly-bin repackage release binaries; hyprmoncfg ships a Go release)
  yay-bin shelly-bin hyprmoncfg btrfs-assistant-git
)

# Clean up the work dir on any exit (success, error, or Ctrl-C). 2>/dev/null
# is in case $WORK never got created (e.g. we exited before mkdir). The
# offline payload cache in $OFFLINE is deliberately NOT cleaned.
trap 'sudo rm -rf "$WORK" 2>/dev/null || true' EXIT

BUILD_MIRRORLIST="$OFFLINE/build-mirrorlist"

# Rank Arch mirrors for ISO-build downloads (offline closure + AUR chroot).
# Override with HYPERWEBSTER_MIRRORLIST=/path/to/mirrorlist. Set
# HYPERWEBSTER_REFRESH_MIRRORS=1 to force re-ranking on the next build.
prepare_build_mirrorlist() {
  if [ -n "${HYPERWEBSTER_MIRRORLIST:-}" ]; then
    echo "==> Using custom build mirrorlist: $HYPERWEBSTER_MIRRORLIST"
    cp "$HYPERWEBSTER_MIRRORLIST" "$BUILD_MIRRORLIST"
    return 0
  fi

  if [ -f "$BUILD_MIRRORLIST" ] && [ -z "${HYPERWEBSTER_REFRESH_MIRRORS:-}" ]; then
    echo "    Reusing cached build mirrorlist ($BUILD_MIRRORLIST)."
    echo "    (set HYPERWEBSTER_REFRESH_MIRRORS=1 to re-rank, or delete the file)"
    return 0
  fi

  echo "==> Preparing Arch mirrorlist for ISO build downloads..."
  mkdir -p "$OFFLINE"
  if command -v reflector >/dev/null 2>&1; then
    echo "    Ranking mirrors with reflector..."
    if ! reflector --latest 20 --sort rate --download-timeout 30 --save "$BUILD_MIRRORLIST" \
        --protocol https; then
      echo "    reflector failed — retrying with a shorter mirror list." >&2
      reflector --latest 10 --sort rate --save "$BUILD_MIRRORLIST" --protocol https \
        || true
    fi
  fi
  if [ ! -s "$BUILD_MIRRORLIST" ]; then
    echo "    reflector not installed or failed — using multi-mirror fallback list."
    echo "    (optional: sudo pacman -S reflector for faster mirror selection)"
    cat > "$BUILD_MIRRORLIST" <<'MIRRORS'
## HyperWebster build fallback mirrorlist (pacman tries each Server in order)
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.lty.me/archlinux/$repo/os/$arch
Server = https://mirrors.mit.edu/archlinux/$repo/os/$arch
Server = https://mirror.math.princeton.edu/pub/archlinux/$repo/os/$arch
Server = https://archlinux.mirror.constant.com/$repo/os/$arch
Server = https://mirror.fcix.net/archlinux/$repo/os/$arch
Server = https://us.arch.niranjan.co/$repo/os/$arch
Server = https://arch.mirror.constant.com/$repo/os/$arch
MIRRORS
  fi
}

write_dl_pacman_conf() {
  cat > "$OFFLINE/dl-pacman.conf" <<DLPAC
[options]
Architecture = x86_64
ParallelDownloads = 8
DisableDownloadTimeout
SigLevel = Required DatabaseOptional

[hyperwebster]
SigLevel = Optional TrustAll
Server = file://$OFFLINE/iso/repo

[core]
Include = $BUILD_MIRRORLIST

[extra]
Include = $BUILD_MIRRORLIST

[omarchy]
SigLevel = Optional TrustAll
Server = https://pkgs.omarchy.org/edge/\$arch

[cachyos]
SigLevel = Optional TrustAll
Server = https://mirror.cachyos.org/repo/x86_64/cachyos
Server = https://cdn.cachyos.org/repo/x86_64/cachyos
DLPAC
}

# Download the full offline-repo closure with mirror refresh + retries.
download_offline_closure() {
  local attempt=1 max_attempts=3
  sudo rm -rf "$OFFLINE/dl-db"
  mkdir -p "$OFFLINE/dl-db"
  while [ "$attempt" -le "$max_attempts" ]; do
    echo "==> Downloading full package dependency closure (attempt $attempt/$max_attempts)..."
    if sudo pacman -Syw --noconfirm \
      --config "$OFFLINE/dl-pacman.conf" \
      --dbpath "$OFFLINE/dl-db" \
      --cachedir "$OFFLINE/iso/repo" \
      "${BASE_PKGS[@]}" "${GPU_ALL_PKGS[@]}" "${LIMINE_TOOLS[@]}"; then
      return 0
    fi
    echo "WARNING: pacman download failed (attempt $attempt/$max_attempts)." >&2
    if [ "$attempt" -lt "$max_attempts" ]; then
      echo "    Refreshing mirrors and retrying..." >&2
      HYPERWEBSTER_REFRESH_MIRRORS=1 prepare_build_mirrorlist
      write_dl_pacman_conf
    fi
    attempt=$((attempt + 1))
  done
  echo "ERROR: package download failed after $max_attempts attempts." >&2
  echo "       Try: HYPERWEBSTER_REFRESH_MIRRORS=1 ./hyperwebster.sh" >&2
  echo "       Or:  sudo reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist" >&2
  echo "            HYPERWEBSTER_MIRRORLIST=/etc/pacman.d/mirrorlist ./hyperwebster.sh" >&2
  return 1
}

# ===========================================================================
# write_installer — emit the live-ISO installer to the given path.
# This function holds the script that runs on the *target* machine inside
# the live ISO (auto-launched on tty1). It is intentionally embedded here so
# this file is the only artifact needed to rebuild the installer ISO.
# ===========================================================================
write_installer() {
  cat > "$1" <<'__INSTALLER_PAYLOAD__'
#!/usr/bin/env bash
set -euo pipefail

MARKER="/tmp/.installer-ran"
if [ -f "$MARKER" ]; then
  echo
  echo "  Installer already ran this session."
  echo "  To retry: rm $MARKER && bash $0"
  echo
  exec /bin/bash
fi
touch "$MARKER"

# Mirror stdout/stderr to /tmp/installer.log. If the script aborts, the user
# can switch to tty2, log in as root, and `cat /tmp/installer.log` to see the
# last "==> ..." marker reached and any error printed by the failing command.
exec > >(tee /tmp/installer.log) 2>&1

if [ ! -d /sys/firmware/efi ]; then
  echo "ERROR: not booted in UEFI mode. UEFI-only installer." >&2
  exec /bin/bash
fi

clear

# --- styled UI helpers (pure bash, no extra packages). They draw to /dev/tty
# directly so the arrow-key redraws never spam the tee'd installer.log. The UI
# is centre-aligned to the console width. --------------------------------------
NSI_G=$'\033[38;5;150m'       # HyperWebster green
NSI_GB=$'\033[1;38;5;150m'    # bold green
NSI_DIM=$'\033[0;90m'         # dim/grey
NSI_B=$'\033[1m'
NSI_R=$'\033[0m'

# Console width (from the real console — stdout is tee'd to a pipe). Default 80.
nsi_cols() {
  local c; c=$(stty size </dev/tty 2>/dev/null | awk '{print $2}')
  case "$c" in ''|*[!0-9]*) c=80 ;; esac
  [ "$c" -ge 20 ] 2>/dev/null || c=80
  printf '%s' "$c"
}
# Left-pad string for centring a block of visible width $1.
nsi_pad() {
  local cols p; cols=$(nsi_cols); p=$(( (cols - $1) / 2 )); [ "$p" -lt 0 ] && p=0
  printf '%*s' "$p" ''
}
# Centred line of PLAIN text. $2=colour code (optional), $3=reset (optional).
cecho() { printf '%s%s%s%s\n' "$(nsi_pad "${#1}")" "${2:-}" "$1" "${3:-}"; }
# Centred read into VAR: cread VAR "prompt". csecret = silent (passwords).
cread()   { printf '%s' "$(nsi_pad "${#2}")" >/dev/tty; read -rp  "$2" "$1" </dev/tty; }
csecret() { printf '%s' "$(nsi_pad "${#2}")" >/dev/tty; read -rsp "$2" "$1" </dev/tty; echo; }

# tui_menu "Title" "opt1" "opt2" ... -> sets MENU_CHOICE (0-based index) + MENU_VALUE.
# Navigate with ↑/↓ (or j/k), Enter selects. Centre-aligned as a block.
tui_menu() {
  local title="$1"; shift
  local -a opts=("$@")
  local n=${#opts[@]} sel=0 first=1 i key rest o w
  local lines=$(( n + 3 ))    # title + blank + n options + hint
  local hint='↑/↓ move · Enter select'
  # Block width = widest of title, "❯ "+option, hint — then centre that block.
  local maxw=${#title}
  for o in "${opts[@]}"; do w=$(( ${#o} + 2 )); [ "$w" -gt "$maxw" ] && maxw=$w; done
  [ "${#hint}" -gt "$maxw" ] && maxw=${#hint}
  local pad; pad=$(nsi_pad "$maxw")
  printf '\033[?25l' >/dev/tty
  while true; do
    if [ "$first" -eq 1 ]; then first=0; else printf '\033[%dA' "$lines" >/dev/tty; fi
    {
      printf '\r\033[2K%s%s%s%s\n\r\033[2K\n' "$pad" "$NSI_GB" "$title" "$NSI_R"
      for i in "${!opts[@]}"; do
        if [ "$i" -eq "$sel" ]; then
          printf '\r\033[2K%s%s❯%s %s%s%s\n' "$pad" "$NSI_GB" "$NSI_R" "$NSI_B" "${opts[$i]}" "$NSI_R"
        else
          printf '\r\033[2K%s  %s%s%s\n' "$pad" "$NSI_DIM" "${opts[$i]}" "$NSI_R"
        fi
      done
      printf '\r\033[2K%s%s%s%s\n' "$pad" "$NSI_DIM" "$hint" "$NSI_R"
    } >/dev/tty
    IFS= read -rsn1 key </dev/tty || true
    case "$key" in
      $'\033')
        IFS= read -rsn2 -t 0.01 rest </dev/tty || true
        case "$rest" in
          '[A'|'OA') sel=$(( (sel - 1 + n) % n )) ;;
          '[B'|'OB') sel=$(( (sel + 1) % n )) ;;
        esac ;;
      k) sel=$(( (sel - 1 + n) % n )) ;;
      j) sel=$(( (sel + 1) % n )) ;;
      '') break ;;
    esac
  done
  printf '\033[?25h' >/dev/tty
  MENU_CHOICE=$sel
  MENU_VALUE="${opts[$sel]}"
}

# Install-progress UI. During the heavy install phase ALL command output is
# redirected to /tmp/installer.log (off-screen) and the user sees only a single
# CENTRED spinner + the current phase name on /dev/tty — calm and consistent
# with the centred menus, no scrolling formatting/build-hook spam. Full detail
# stays in the log (Ctrl+Alt+F2 -> cat /tmp/installer.log).
NSI_PHASE_FILE=/tmp/nsi-phase
NSI_SPIN_PID=""
# Centred line drawn straight to the real console (stdout is the log mid-install).
tcecho() { printf '%s%s%s%s\n' "$(nsi_pad "${#1}")" "${2:-}" "$1" "${3:-}" >/dev/tty; }
# Set the phase label the spinner shows.
nsi_phase() { printf '%s' "$1" > "$NSI_PHASE_FILE" 2>/dev/null || true; }
nsi_spin_start() {
  printf '\033[?25l' >/dev/tty   # hide cursor
  (
    set +e
    local frames='/-\|' i=0 msg vis pad
    while true; do
      msg=$(cat "$NSI_PHASE_FILE" 2>/dev/null); [ -n "$msg" ] || msg="Working"
      vis=$(( ${#msg} + 5 ))     # frame + 2 spaces + msg + ellipsis
      pad=$(nsi_pad "$vis")
      printf '\r\033[2K%s%s%s%s  %s%s…%s' \
        "$pad" "$NSI_GB" "${frames:i%4:1}" "$NSI_R" "$NSI_B" "$msg" "$NSI_R" >/dev/tty
      i=$((i+1)); sleep 0.15
    done
  ) &
  NSI_SPIN_PID=$!
}
nsi_spin_stop() {
  [ -n "$NSI_SPIN_PID" ] && { kill "$NSI_SPIN_PID" 2>/dev/null || true; wait "$NSI_SPIN_PID" 2>/dev/null || true; NSI_SPIN_PID=""; }
  printf '\r\033[2K\033[?25h' >/dev/tty   # clear the spinner line, show cursor
}
# ERR trap during install: stop the spinner, restore on-screen output, and show
# which phase failed + the tail of the log (full detail on tty2).
nsi_fail() {
  trap - ERR
  nsi_spin_stop
  exec >/dev/tty 2>&1
  echo
  cecho "Install FAILED at: $(cat "$NSI_PHASE_FILE" 2>/dev/null)" "$NSI_GB" "$NSI_R"
  cecho "See the log on tty2:  Ctrl+Alt+F2  →  cat /tmp/installer.log" "$NSI_DIM" "$NSI_R"
  echo
  tail -n 25 /tmp/installer.log 2>/dev/null
}

# Banner — centred Starman (detailed image-to-ASCII, helmet crop). ASCII only.
STARMAN_LINES=(
  '                                                 .     '
  '                                                       '
  '                                                       '
  'oo                                                     '
  'o.                      ........                       '
  '                   ...  ..  .....o.                    '
  '                 ..              ....                  '
  '               ..           ..oo.   ......             '
  '               ..     ..     o88o.   .....             '
  '               . .   ...  .  .888o.  ... .             '
  '               .     ...             ......            '
  '               ..    ...             .... .            '
)
for line in "${STARMAN_LINES[@]}"; do
  printf '%s%s%s\n' "$(nsi_pad ${#line})" "$NSI_GB" "$line"
done
printf '\n'
BPAD=$(nsi_pad 46)
printf '%s%s%s\n'   "$BPAD" "$NSI_GB" "┌────────────────────────────────────────────┐"
printf '%s%s%s\n'   "$BPAD" "$NSI_GB" "│        HyperWebster · hyperarch · Starman    │"
printf '%s%s%s\n'   "$BPAD" "$NSI_GB" "└────────────────────────────────────────────┘"
printf '%s'         "$NSI_R"
cecho "Arch · Hyprland · Caelestia · gaming desktop — offline installer" "$NSI_DIM" "$NSI_R"
echo

# ----------------------------------------------------- offline payload ------
# Everything installs from the package repo bundled on the install media.
# archiso's copytoram defaults to AUTO and fires on every non-optical boot
# (USB stick + enough RAM): the initramfs copies airootfs.sfs to RAM, then
# UNMOUNTS and rmdir's /run/archiso/bootmnt — taking /hyperwebster with it. CD
# boots are exempt, which is why VM -cdrom certification never caught it.
# Remount the install media by the UUID archiso itself booted from.
HYPERWEBSTER_PAYLOAD=/run/archiso/bootmnt/hyperwebster
if [ ! -f "$HYPERWEBSTER_PAYLOAD/repo/hyperwebster.db" ]; then
  cecho "Boot media unmounted by copytoram — remounting the offline repo..." "$NSI_DIM" "$NSI_R"
  iso_uuid=$(sed -n 's/.*archisosearchuuid=\([^ ]*\).*/\1/p' /proc/cmdline)
  iso_label=$(sed -n 's/.*archisolabel=\([^ ]*\).*/\1/p' /proc/cmdline)
  iso_dev=""
  for _ in $(seq 1 15); do
    if [ -n "$iso_uuid" ] && [ -e "/dev/disk/by-uuid/$iso_uuid" ]; then
      iso_dev="/dev/disk/by-uuid/$iso_uuid"; break
    fi
    if [ -n "$iso_label" ] && [ -e "/dev/disk/by-label/$iso_label" ]; then
      iso_dev="/dev/disk/by-label/$iso_label"; break
    fi
    sleep 1
  done
  if [ -n "$iso_dev" ]; then
    mkdir -p /run/archiso/bootmnt
    mount -o ro "$iso_dev" /run/archiso/bootmnt || true
  fi
fi
if [ ! -f "$HYPERWEBSTER_PAYLOAD/repo/hyperwebster.db" ] || [ ! -f "$HYPERWEBSTER_PAYLOAD/base-packages.list" ]; then
  echo "ERROR: offline package repo not found on the install media" >&2
  echo "       (expected $HYPERWEBSTER_PAYLOAD/repo). Bad burn or wrong ISO?" >&2
  exec /bin/bash
fi
# Strip comments/blank lines so the list file can be annotated.
mapfile -t BASE_PKGS < <(grep -vE '^\s*(#|$)' "$HYPERWEBSTER_PAYLOAD/base-packages.list")
cecho "Offline repo found (${#BASE_PKGS[@]} base packages)." "$NSI_DIM" "$NSI_R"
echo

# pacman config used for every install-time operation: ONLY the bundled repo.
# The installed system gets the normal online mirrors instead (written later).
# SigLevel Never: the bundled packages were verified when the ISO was BUILT
# (official sigs checked on download; AUR pkgs built locally) — the ISO is the
# trust boundary. Anything weaker fails: e.g. 'Optional TrustAll' still tries
# to VERIFY any signature embedded in the repo db and dies on the missing key.
cat > /tmp/hyperwebster-pacman.conf <<'OFFLINECONF'
[options]
Architecture = x86_64
SigLevel = Never

[hyperwebster]
Server = file:///run/archiso/bootmnt/hyperwebster/repo
OFFLINECONF

# ---------------------------------------------------------------- network ----
# The install is fully offline — no network is needed here or on first boot.
# Wired boxes DHCP automatically via NetworkManager; Wi-Fi users connect from
# the desktop's Wi-Fi panel (click-to-connect) or nm-connection-editor on first
# boot. So the installer asks for nothing here.

# ---------------------------------------------------------------- prompts ----
while true; do
  cread HOSTNAME "Hostname [hyperarch]: "
  HOSTNAME="${HOSTNAME:-hyperarch}"
  [[ "$HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$ ]] && break
  cecho "Invalid (RFC 1123: letters/digits/hyphen, no leading hyphen, max 63 chars)."
done

while true; do
  cread USERNAME "Username: "
  [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]{0,30}$ ]] && break
  cecho "Invalid (lowercase, starts a-z or _, max 31 chars)."
done

while true; do
  csecret PW1 "Password for $USERNAME (also used for root): "
  csecret PW2 "Confirm password: "
  if [ -z "$PW1" ]; then cecho "Empty — try again."; continue; fi
  if [ "$PW1" != "$PW2" ]; then cecho "Mismatch — try again."; continue; fi
  break
done
USER_PW="$PW1"
echo

# Localisation — pick a region from a curated list; it sets the timezone, locale,
# console keymap and Hyprland xkb layout together (no more three cryptic prompts).
# "Other" drops to the search-based prompts for anything not listed. The curated
# values are all standard tzdata/locale.gen/kbd names present on the ISO.
tui_menu "Where are you?  (sets time zone, language & keyboard)" \
  "United Kingdom" \
  "Ireland" \
  "United States" \
  "Canada" \
  "Australia" \
  "Germany" \
  "France" \
  "Spain" \
  "Italy" \
  "Netherlands" \
  "Other (advanced — type & search)"
case "$MENU_VALUE" in
  "United Kingdom") TIMEZONE=Europe/London;    LOCALE=en_GB.UTF-8; KEYMAP=uk;        XKB_LAYOUT=gb ;;
  "Ireland")        TIMEZONE=Europe/Dublin;    LOCALE=en_IE.UTF-8; KEYMAP=uk;        XKB_LAYOUT=gb ;;
  "United States")  TIMEZONE=America/New_York; LOCALE=en_US.UTF-8; KEYMAP=us;        XKB_LAYOUT=us ;;
  "Canada")         TIMEZONE=America/Toronto;  LOCALE=en_CA.UTF-8; KEYMAP=us;        XKB_LAYOUT=us ;;
  "Australia")      TIMEZONE=Australia/Sydney; LOCALE=en_AU.UTF-8; KEYMAP=us;        XKB_LAYOUT=us ;;
  "Germany")        TIMEZONE=Europe/Berlin;    LOCALE=de_DE.UTF-8; KEYMAP=de-latin1; XKB_LAYOUT=de ;;
  "France")         TIMEZONE=Europe/Paris;     LOCALE=fr_FR.UTF-8; KEYMAP=fr-latin1; XKB_LAYOUT=fr ;;
  "Spain")          TIMEZONE=Europe/Madrid;    LOCALE=es_ES.UTF-8; KEYMAP=es;        XKB_LAYOUT=es ;;
  "Italy")          TIMEZONE=Europe/Rome;      LOCALE=it_IT.UTF-8; KEYMAP=it;        XKB_LAYOUT=it ;;
  "Netherlands")    TIMEZONE=Europe/Amsterdam; LOCALE=nl_NL.UTF-8; KEYMAP=us;        XKB_LAYOUT=us ;;
  *)
    # Other (advanced): the previous search-based prompts. Enter '?text' to search.
    while true; do
      cread TIMEZONE "Timezone [Europe/London] ('?text' searches): "
      TIMEZONE="${TIMEZONE:-Europe/London}"
      if [[ "$TIMEZONE" == \?* ]]; then
        timedatectl list-timezones 2>/dev/null | grep -i -- "${TIMEZONE#\?}" | head -25 | sed 's/^/    /'
        continue
      fi
      [ -f "/usr/share/zoneinfo/$TIMEZONE" ] && break
      cecho "Not found (e.g. Europe/London, America/New_York, Australia/Sydney)."
    done
    while true; do
      cread LOCALE "Locale [en_GB.UTF-8] ('?text' searches): "
      LOCALE="${LOCALE:-en_GB.UTF-8}"
      if [[ "$LOCALE" == \?* ]]; then
        grep -oE '^#?[^ ]+ ' /etc/locale.gen | tr -d '# ' | grep -i -- "${LOCALE#\?}" | head -25 | sed 's/^/    /'
        continue
      fi
      grep -oE '^#?[^ ]+ ' /etc/locale.gen | tr -d '# ' | grep -qxF "$LOCALE" && break
      cecho "Not found (e.g. en_GB.UTF-8, en_US.UTF-8, de_DE.UTF-8)."
    done
    while true; do
      cread KEYMAP "Console keymap [uk] ('?text' searches): "
      KEYMAP="${KEYMAP:-uk}"
      if [[ "$KEYMAP" == \?* ]]; then
        localectl list-keymaps 2>/dev/null | grep -i -- "${KEYMAP#\?}" | head -25 | sed 's/^/    /'
        continue
      fi
      localectl list-keymaps 2>/dev/null | grep -qxF "$KEYMAP" && break
      cecho "Not found (e.g. uk, us, de-latin1, fr-latin1)."
    done
    # Map the console keymap to an XKB layout for Hyprland's kb_layout. The names
    # usually agree (us, de, it, es, pl...); this table covers the common
    # exceptions, and the fallback strips variant suffixes (cz-qwertz -> cz).
    case "$KEYMAP" in
      uk) XKB_LAYOUT="gb" ;;
      fr-latin1|fr-latin9) XKB_LAYOUT="fr" ;;
      pt-latin1|pt-latin9) XKB_LAYOUT="pt" ;;
      br-abnt2) XKB_LAYOUT="br" ;;
      la-latin1) XKB_LAYOUT="latam" ;;
      sv-latin1) XKB_LAYOUT="se" ;;
      sg|sg-latin1) XKB_LAYOUT="ch" ;;
      dvorak*) XKB_LAYOUT="us" ;;
      *) XKB_LAYOUT="${KEYMAP%%[-.]*}" ;;
    esac
    ;;
esac
cecho "Region set: ${TIMEZONE} · ${LOCALE} · keymap ${KEYMAP}" "$NSI_DIM" "$NSI_R"

# Disk — arrow-key pick from the real disks, then a plain Yes/No confirm
# (defaults to No). No more typing the device path.
echo
mapfile -t DISKS < <(lsblk -d -n -p -o NAME,SIZE,MODEL | grep -Ev '/dev/(loop|sr|zram|fd)')
if [ "${#DISKS[@]}" -eq 0 ]; then
  cecho "No disks found. Dropping to shell."
  exec /bin/bash
fi
while true; do
  DISK_LABELS=()
  for d in "${DISKS[@]}"; do
    DISK_LABELS+=("$(awk '{name=$1; size=$2; $1=""; $2=""; sub(/^[[:space:]]+/,""); printf "%-16s %-9s %s", name, size, $0}' <<<"$d")")
  done
  tui_menu "Install to which disk?  (everything on it is erased)" "${DISK_LABELS[@]}"
  DISK=$(awk '{print $1}' <<<"${DISKS[$MENU_CHOICE]}")
  tui_menu "Erase $DISK and install HyperWebster?" \
    "No — choose a different disk" \
    "Yes — ERASE $DISK and install"
  [ "$MENU_CHOICE" -eq 1 ] && break
done

echo
tui_menu "Encrypt the root disk with LUKS2?" \
  "Yes — LUKS2 encryption (recommended)" \
  "No — plain btrfs (no encryption)"
USE_LUKS=$MENU_CHOICE

LUKS_PW=""
if [ "$USE_LUKS" -eq 0 ]; then
  while true; do
    csecret LUKS_PW1 "LUKS passphrase (fallback when TPM unlock fails): "
    csecret LUKS_PW2 "Confirm LUKS passphrase: "
    if [ -z "$LUKS_PW1" ]; then cecho "Empty — try again."; continue; fi
    if [ "$LUKS_PW1" != "$LUKS_PW2" ]; then cecho "Mismatch — try again."; continue; fi
    break
  done
  LUKS_PW="$LUKS_PW1"
  cecho "Root partition will be LUKS2-encrypted." "$NSI_DIM" "$NSI_R"
  LUKS_TPM=1
  if [ -e /dev/tpmrm0 ] || [ -e /dev/tpm0 ]; then
    echo
    tui_menu "Enroll TPM2 for passphrase-free unlock at boot?" \
      "Yes — TPM2 auto-unlock (passphrase stays as fallback)" \
      "No — passphrase only"
    LUKS_TPM=$MENU_CHOICE
    [ "$LUKS_TPM" -eq 0 ] && cecho "TPM2 will be enrolled after install." "$NSI_DIM" "$NSI_R"
  else
    cecho "No TPM detected — passphrase-only LUKS." "$NSI_DIM" "$NSI_R"
  fi
else
  cecho "Root partition will NOT be encrypted." "$NSI_DIM" "$NSI_R"
  LUKS_TPM=1
fi

if [[ "$DISK" =~ nvme|mmcblk ]]; then
  EFI_PART="${DISK}p1"; ROOT_PART="${DISK}p2"
else
  EFI_PART="${DISK}1"; ROOT_PART="${DISK}2"
fi

# ---------------------------------------------------------------- install ----
# Go quiet + centred for the heavy phase: the prompts are done, so hide every
# command's output to the log and show a single centred spinner with the current
# phase name (consistent with the centred menus, no formatting/build-hook spam).
clear
# Silence kernel printk on the console — disk format/mount triggers harmless
# btrfs/ext4 probe messages ("VFS: Can't find ext4 filesystem") that write
# straight to the VT and would splatter over the clean spinner. (dmesg keeps
# them; this only stops console printing. Not restored — a reboot follows.)
dmesg -D 2>/dev/null || echo 1 > /proc/sys/kernel/printk 2>/dev/null || true
tcecho "Installing HyperWebster" "$NSI_GB" "$NSI_R"
tcecho "this takes a few minutes — sit tight" "$NSI_DIM" "$NSI_R"
printf '\n' >/dev/tty
nsi_phase "Preparing the disk"
exec >>/tmp/installer.log 2>&1
trap nsi_fail ERR
nsi_spin_start
echo "==> Wiping $DISK..."
swapoff -a || true
umount -R /mnt 2>/dev/null || true
wipefs -af "$DISK"
sgdisk --zap-all "$DISK"

echo "==> Partitioning (1G EFI + rest btrfs)..."
# 1 GiB ESP (was 512M): UKIs are self-contained kernel+initramfs+microcode, and
# the NVIDIA UKI is ~139 MB (driver + GSP firmware). With ENABLE_LIMINE_FALLBACK
# (a 2nd UKI) plus multiple kernel versions, a 512 MB ESP can fill and UKI writes
# then fail (finding F4 secondary risk). 1 GiB is safe headroom on every GPU.
sgdisk -n1:0:+1G -t1:ef00 -c1:EFI "$DISK"
sgdisk -n2:0:0     -t2:8300 -c2:ROOT "$DISK"
partprobe "$DISK"
udevadm settle

echo "==> Formatting (btrfs root for Limine snapshots)..."
mkfs.fat -F32 -n EFI "$EFI_PART"

LUKS_NAME="hyperwebster-root"
BTRFS_DEV="$ROOT_PART"
LUKS_PARTUUID=""
LUKS_UUID=""
if [ "$USE_LUKS" -eq 0 ]; then
  echo "==> Encrypting $ROOT_PART with LUKS2..."
  echo -n "$LUKS_PW" | cryptsetup luksFormat "$ROOT_PART" --type luks2 --batch-mode
  echo -n "$LUKS_PW" | cryptsetup open "$ROOT_PART" "$LUKS_NAME"
  BTRFS_DEV="/dev/mapper/$LUKS_NAME"
  LUKS_PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_PART")
  LUKS_UUID=$(cryptsetup luksUUID "$ROOT_PART")
fi
mkfs.btrfs -f -L ROOT "$BTRFS_DEV"

# Btrfs subvolume layout for snapshot/rollback (root-only snapshots):
#   @          -> /            (snapshotted + rolled back)
#   @home      -> /home        (separate, so a rollback never reverts user data)
#   @snapshots -> /.snapshots  (separate, so snapshots survive a rollback of @)
#   @log       -> /var/log     (separate, so logs survive a rollback — useful)
echo "==> Creating btrfs subvolumes..."
mount "$BTRFS_DEV" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@log
umount /mnt

echo "==> Mounting subvolumes..."
BTRFS_OPTS="noatime,compress=zstd,space_cache=v2"
mount -o "$BTRFS_OPTS,subvol=@" "$BTRFS_DEV" /mnt
mkdir -p /mnt/boot /mnt/home /mnt/.snapshots /mnt/var/log
mount -o "$BTRFS_OPTS,subvol=@home"      "$BTRFS_DEV" /mnt/home
mount -o "$BTRFS_OPTS,subvol=@snapshots" "$BTRFS_DEV" /mnt/.snapshots
mount -o "$BTRFS_OPTS,subvol=@log"       "$BTRFS_DEV" /mnt/var/log
mount "$EFI_PART" /mnt/boot

# ------------------------------------------------------------ GPU drivers ----
# Hardware-detect the GPU(s) and pick driver packages, borrowing CachyOS chwd's
# method: scan PCI display-class controllers (class 0300/0302/0380) and map the
# vendor id (10de NVIDIA / 1002 AMD / 8086 Intel) to a driver set — plus the VM
# vendors so Hyprland comes up in a guest. Done natively (no chwd binary).
# The default kernel is linux-cachyos (bundled offline); stock linux remains as
# a Limine fallback entry. CachyOS repo stanzas are bootstrapped at install.
# Multiple GPUs union their package sets (e.g. an Intel/AMD iGPU + NVIDIA dGPU).
# ALL variants below are present in the offline repo (see GPU_ALL_PKGS in the
# builder — keep the two in sync).
echo "==> Detecting GPU(s)..."
GPU_NVIDIA=0; GPU_AMD=0; GPU_INTEL=0; GPU_VM=0
IGPU_PCI_ID=""   # vendor:device of the iGPU (for hybrid Vulkan device steering)
while IFS= read -r gpuline; do
  case "$gpuline" in
    *'[10de:'*) GPU_NVIDIA=1 ;;
    *'[1002:'*) GPU_AMD=1;   [ -z "$IGPU_PCI_ID" ] && IGPU_PCI_ID=$(printf '%s\n' "$gpuline" | grep -oE '1002:[0-9a-fA-F]{4}' | head -1) ;;
    *'[8086:'*) GPU_INTEL=1; [ -z "$IGPU_PCI_ID" ] && IGPU_PCI_ID=$(printf '%s\n' "$gpuline" | grep -oE '8086:[0-9a-fA-F]{4}' | head -1) ;;
    *'[1af4:'*|*'[1b36:'*|*'[1234:'*|*'[15ad:'*|*'[80ee:'*) GPU_VM=1 ;;
  esac
done < <(lspci -nn 2>/dev/null | grep -Ei 'VGA compatible controller|3D controller|Display controller')

# Hybrid-laptop awareness. An iGPU (Intel/AMD) present ALONGSIDE an NVIDIA dGPU on
# a LAPTOP is almost always muxless Optimus: the internal panel is wired to the
# iGPU and the dGPU is only a secondary render device. Forcing the NVIDIA GLX/
# VA-API globally — correct when the display hangs off the NVIDIA card (desktop,
# or a laptop MUX set to discrete) — then breaks/slows the iGPU-driven Wayland
# session and keeps the dGPU awake on battery. So on a hybrid laptop we keep the
# iGPU primary, ship prime-run for on-demand offload, and enable dGPU runtime
# power management, while STILL installing the NVIDIA driver + KMS so offload
# works. Desktops with NVIDIA present are unaffected (no laptop chassis/battery).
# Override the heuristic with HYPERWEBSTER_GPU_PRIMARY=nvidia|igpu|auto (default auto).
GPU_HYBRID_LAPTOP=0
IGPU_VAAPI=radeonsi
if [ "$GPU_NVIDIA" = 1 ] && { [ "$GPU_INTEL" = 1 ] || [ "$GPU_AMD" = 1 ]; }; then
  is_laptop=0
  ct=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo 0)
  case "$ct" in 8|9|10|11|14|30|31|32) is_laptop=1 ;; esac
  for b in /sys/class/power_supply/BAT*; do [ -e "$b" ] && is_laptop=1; done
  case "${HYPERWEBSTER_GPU_PRIMARY:-auto}" in
    igpu)   GPU_HYBRID_LAPTOP=1 ;;
    nvidia) GPU_HYBRID_LAPTOP=0 ;;
    *)      GPU_HYBRID_LAPTOP=$is_laptop ;;
  esac
  # iGPU VA-API backend (the panel-connected decoder): Intel -> iHD, AMD -> radeonsi.
  [ "$GPU_INTEL" = 1 ] && IGPU_VAAPI=iHD
fi

GPU_PKGS=(mesa vulkan-icd-loader)
GPU_SUMMARY=()
if [ "$GPU_NVIDIA" = 1 ]; then
  # Open-kernel-module NVIDIA (Turing/RTX+; the current default). DKMS builds
  # against every installed kernel (linux + linux-cachyos); headers for both
  # ship in the base set.
  GPU_PKGS+=(nvidia-open-dkms nvidia-utils egl-wayland libva-nvidia-driver nvidia-settings linux-headers)
  GPU_SUMMARY+=("NVIDIA (nvidia-open-dkms + Wayland KMS)")
fi
if [ "$GPU_AMD" = 1 ]; then
  GPU_PKGS+=(vulkan-radeon)
  GPU_SUMMARY+=("AMD (mesa / vulkan-radeon)")
fi
if [ "$GPU_INTEL" = 1 ]; then
  GPU_PKGS+=(vulkan-intel intel-media-driver)
  GPU_SUMMARY+=("Intel (mesa / vulkan-intel)")
fi
if [ "$GPU_VM" = 1 ]; then
  GPU_PKGS+=(qemu-guest-agent spice-vdagent)
  GPU_SUMMARY+=("VM guest (virtio / qemu)")
fi
if [ "${#GPU_SUMMARY[@]}" -eq 0 ]; then
  # Nothing recognised — software rendering keeps Hyprland able to start.
  GPU_PKGS+=(vulkan-swrast)
  GPU_SUMMARY+=("unknown — software fallback (vulkan-swrast)")
fi
if [ "$GPU_HYBRID_LAPTOP" = 1 ]; then
  # prime-run for on-demand dGPU offload; iGPU stays primary (see env block below).
  GPU_PKGS+=(nvidia-prime)
  GPU_SUMMARY+=("hybrid laptop -> iGPU primary + NVIDIA PRIME offload (prime-run)")
fi
echo "    Driver target(s): ${GPU_SUMMARY[*]}"

nsi_phase "Installing the HyperWebster desktop (this is the slow part)"
pacstrap -C /tmp/hyperwebster-pacman.conf -K /mnt "${BASE_PKGS[@]}" "${GPU_PKGS[@]}"

echo "==> Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# F7: genfstab inherits the ESP's live mount options (fmask=0022,dmask=0022),
# which make /boot world-readable — exposing the bootloader random-seed and
# limine.conf (kernel cmdline, root PARTUUID, snapshot history) to any local
# user. systemd's bootctl flags this at every boot as a security hole. Tighten
# the vfat (ESP) line to root rw / group r / others none: files rw-r----- and
# dirs rwxr-x---. (Only the ESP is vfat here, so the vfat-line match is exact.)
sed -i -E '/[[:space:]]vfat[[:space:]]/{ s/fmask=[0-7]+/fmask=0137/; s/dmask=[0-7]+/dmask=0027/ }' /mnt/etc/fstab
if grep -qE '[[:space:]]vfat[[:space:]].*fmask=0137' /mnt/etc/fstab; then
  echo "    ESP hardened (fmask=0137,dmask=0027 — not world-readable)."
else
  echo "    WARNING: could not harden ESP mount perms in fstab — review /boot fmask/dmask."
fi

nsi_phase "Configuring the system"
echo "==> Configuring base system in chroot..."
# Localisation from the prompts (written from outside the chroot — simpler
# than threading variables through a quoted heredoc).
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /mnt/etc/localtime
sed -i "s|^#${LOCALE} |${LOCALE} |" /mnt/etc/locale.gen
# en_US.UTF-8 as an always-present fallback locale.
sed -i 's|^#en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|' /mnt/etc/locale.gen
echo "LANG=$LOCALE" > /mnt/etc/locale.conf
echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf
# Resolve .local hostnames via Avahi (printers, other LAN boxes): insert
# mdns_minimal before the resolve/dns sources, the standard nss-mdns setup.
sed -i '/^hosts:/ s/resolve/mdns_minimal [NOTFOUND=return] resolve/' /mnt/etc/nsswitch.conf
arch-chroot /mnt /bin/bash <<'CHROOT'
set -e
hwclock --systohc
locale-gen
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable cups.socket
systemctl enable avahi-daemon.service
systemctl enable power-profiles-daemon.service
# Process sysusers so the 'sddm' system user exists (pacstrap doesn't run
# the package's sysusers.d automatically). Harmless if already present.
systemd-sysusers || true
CHROOT

# --------------------------------------------------------------- Plymouth ----
# Boot splash between Limine and the SDDM greeter: insert the `plymouth`
# initramfs hook right after the init manager hook and set the HyperWebster theme
# (the "NO SIGNAL / 入力信号なし" logo centred on black). With the quiet/splash
# kernel cmdline, the boot shows that splash instead of scrolling kernel text.
echo "==> Configuring Plymouth (HyperWebster boot splash)..."
# Ship the HyperWebster Plymouth theme (vendored). Root dir is 'hyperwebster' ->
# /usr/share/plymouth/themes/hyperwebster. Must land BEFORE the initramfs rebuild
# below so the theme's images/script are embedded in the initramfs.
install -d -m 755 /mnt/usr/share/plymouth/themes
tar -xzf "$HYPERWEBSTER_PAYLOAD/vendor/hyperwebster-plymouth.tar.gz" \
  -C /mnt/usr/share/plymouth/themes
# The plymouth hook goes right after the init manager hook. Arch's default
# mkinitcpio.conf now uses the `systemd` hook (not `udev`), so handle both:
# plymouth after `systemd` if present, else after `udev`. Idempotent.
if ! grep -qE '^HOOKS=.*\bplymouth\b' /mnt/etc/mkinitcpio.conf; then
  if grep -qE '^HOOKS=.*\bsystemd\b' /mnt/etc/mkinitcpio.conf; then
    sed -i '/^HOOKS=/ s/\bsystemd\b/systemd plymouth/' /mnt/etc/mkinitcpio.conf
  else
    sed -i '/^HOOKS=/ s/\budev\b/udev plymouth/' /mnt/etc/mkinitcpio.conf
  fi
fi
# Set HyperWebster as the default theme (no -R: the mkinitcpio -P below rebuilds the
# initramfs and embeds it). Falls back to the built-in spinner if it can't apply.
arch-chroot /mnt plymouth-set-default-theme hyperwebster \
  || arch-chroot /mnt plymouth-set-default-theme spinner || true

# LUKS: initramfs must unlock the encrypted root before btrfs mounts.
# sd-encrypt (systemd in initramfs) supports TPM2 tokens from systemd-cryptenroll.
if [ "$USE_LUKS" -eq 0 ]; then
  if ! grep -qE '^HOOKS=.*\bsd-encrypt\b' /mnt/etc/mkinitcpio.conf; then
    if grep -qE '^HOOKS=.*\bencrypt\b' /mnt/etc/mkinitcpio.conf; then
      sed -i '/^HOOKS=/ s/\bencrypt\b/sd-encrypt/' /mnt/etc/mkinitcpio.conf
    else
      sed -i '/^HOOKS=/ s/\bfilesystems\b/sd-encrypt filesystems/' /mnt/etc/mkinitcpio.conf
    fi
  fi
  echo "$LUKS_NAME PARTUUID=$LUKS_PARTUUID none luks" >> /mnt/etc/crypttab
  chmod 600 /mnt/etc/crypttab
  echo "    LUKS2 configured (sd-encrypt hook + /etc/crypttab)."
fi

# ------------------------------------------------------------- NVIDIA KMS ----
# Borrowed from chwd's pre_install hook: early-load the NVIDIA modules and drop
# the 'kms' hook (which would otherwise bind nouveau to the card), enable DRM
# modeset, and set the Wayland EGL/VA env. This is what actually lets Hyprland
# start on NVIDIA. No-op on AMD/Intel/VM-only systems.
if [ "$GPU_NVIDIA" = 1 ]; then
  echo "==> Configuring NVIDIA DRM/KMS for Wayland (chwd-style)..."
  install -d -m 755 /mnt/etc/mkinitcpio.conf.d
  cat > /mnt/etc/mkinitcpio.conf.d/10-hyperwebster-nvidia.conf <<'NV'
# Generated by HyperWebster. Early-load the NVIDIA modules for KMS.
MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
NV
  cat > /mnt/etc/mkinitcpio.conf.d/20-hyperwebster-nvidia-kms.conf <<'NVK'
# Generated by HyperWebster. Drop the 'kms' hook so nouveau isn't pulled in early.
HOOKS=(${HOOKS[@]/kms/})
NVK
  cat > /mnt/etc/modprobe.d/nvidia.conf <<'NVMOD'
options nvidia_drm modeset=1 fbdev=1
NVMOD
  # System-wide EGL/VA env. caelestia symlinks ~/.config/hypr, so per-user hypr
  # env files would be clobbered — /etc/environment is read for the session.
  if [ "$GPU_HYBRID_LAPTOP" = 1 ]; then
    # Muxless Optimus: the iGPU drives the panel. Do NOT force NVIDIA GLX/VA-API
    # globally — that would push the whole session onto the dGPU. Leave GLX to the
    # iGPU, point VA-API at the iGPU decoder, and let apps opt into the dGPU with
    # `prime-run`. Enable dGPU runtime power management (D3) so it sleeps when idle
    # (Turing+; nvidia-open supports it — matches the nvidia-open-dkms gate).
    cat >> /mnt/etc/environment <<NVENVH
# --- HyperWebster hybrid-laptop GPU env (iGPU primary; run dGPU apps with prime-run) ---
LIBVA_DRIVER_NAME=$IGPU_VAAPI
NVENVH
    # RTD3 Cause 2 (2026-06-20 hybrid battery finding): renderD128 is the NVIDIA
    # node (first/default), so naive Vulkan clients open the dGPU and pin it out of
    # runtime-D3. Steer mesa's default Vulkan device to the iGPU so only prime-run
    # apps touch the dGPU. prime-run still wins (it sets __NV_PRIME_RENDER_OFFLOAD
    # + __VK_LAYER_NV_optimus, which override this). GL/EGL clients on Wayland
    # already render on the compositor's iGPU; VA-API is pinned to the iGPU above.
    # NOTE: best-effort steering — the on-battery dGPU-sleep re-test is the gate.
    if [ -n "$IGPU_PCI_ID" ]; then
      cat >> /mnt/etc/environment <<NVENVS
MESA_VK_DEVICE_SELECT=$IGPU_PCI_ID
NVENVS
    fi
    cat > /mnt/etc/modprobe.d/nvidia-pm.conf <<'NVPM'
# Fine-grained dGPU runtime power management for Optimus battery life (Turing+).
options nvidia NVreg_DynamicPowerManagement=0x02
NVPM
    install -d -m 755 /mnt/etc/udev/rules.d
    cat > /mnt/etc/udev/rules.d/80-hyperwebster-nvidia-pm.rules <<'NVUDEV'
# Let the NVIDIA dGPU autosuspend when idle (runtime D3). VGA + 3D controllers.
#
# RTD3 Cause 1 (2026-06-20 hardware test, Acer AMD iGPU + RTX 3050): the nvidia
# driver binds the dGPU INSIDE the initramfs (mkinitcpio `kms` hook pulls it in
# even with MODULES=()), before real-root udevd exists. Coldplug then replays the
# device as ACTION=="add", which an ACTION=="bind" rule never matched, leaving
# power/control at the kernel default "on" (dGPU never reached D3, ~4 W idle).
# DRIVER=nvidia is already set at coldplug, so match the bound device with NO
# ACTION gate. Keep restoring "auto" on unbind for a later rebind/probe.
SUBSYSTEM=="pci", DRIVERS=="nvidia", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
SUBSYSTEM=="pci", DRIVERS=="nvidia", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="unbind", SUBSYSTEM=="pci", DRIVERS=="nvidia", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="unbind", SUBSYSTEM=="pci", DRIVERS=="nvidia", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
NVUDEV
  else
    # NVIDIA drives the display (desktop, or a laptop MUX set to discrete): force
    # the NVIDIA GLX/VA-API session-wide.
    cat >> /mnt/etc/environment <<'NVENV'
# --- HyperWebster NVIDIA Wayland env ---
LIBVA_DRIVER_NAME=nvidia
__GLX_VENDOR_LIBRARY_NAME=nvidia
NVD_BACKEND=direct
NVENV
  fi
fi

# ---------------------------------------------------------- Acer power -------
# Acer Predator/Nitro laptops keep the dGPU's higher power states LOCKED until
# acer_wmi loads with predator_v4=1 — then the NitroSense/Turbo key cycles them
# (e.g. 35->40->50->60 W). HyperWebster didn't set this out of the box, so the dGPU
# was capped low (hardware test 2026-06-20). Bake it in, gated on Acer hardware
# AND a kernel acer_wmi that accepts the option, so non-Acer machines are
# untouched. nvidia-powerd (Dynamic Boost) is enabled when an NVIDIA driver is
# present (the unit only exists then). Platform profile stays the Omarchy default
# (balanced) — the user can raise it. Source: 28allday/Acer-Power-Control-Omarchy.
SYS_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")
if printf '%s' "$SYS_VENDOR" | grep -qi acer \
   && modinfo -p acer_wmi 2>/dev/null | grep -q "^predator_v4:"; then
  echo "==> Acer laptop detected — unlocking Predator/Nitro GPU power (predator_v4=1)..."
  printf 'options acer_wmi predator_v4=1\n' > /mnt/etc/modprobe.d/acer-wmi.conf
  if [ "$GPU_NVIDIA" = 1 ]; then
    arch-chroot /mnt systemctl enable nvidia-powerd >/dev/null 2>&1 \
      && echo "    nvidia-powerd enabled (Dynamic Boost)" \
      || echo "    nvidia-powerd not enabled (optional)"
  fi
fi

nsi_phase "Installing the bootloader"
echo "==> Installing Limine bootloader (UEFI)..."
if [ "$USE_LUKS" -eq 0 ]; then
  BTRFS_UUID=$(blkid -s UUID -o value "$BTRFS_DEV")
  # sd-encrypt uses rd.luks.* (LUKS superblock UUID), not legacy cryptdevice=.
  KERNEL_OPTS="rd.luks.name=$LUKS_UUID=$LUKS_NAME root=UUID=$BTRFS_UUID rw rootflags=subvol=@"
else
  ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_PART")
  KERNEL_OPTS="root=PARTUUID=$ROOT_PARTUUID rw rootflags=subvol=@"
fi
# Root is the btrfs @ subvolume — append quiet boot flags without clobbering LUKS
# rd.luks.name= when encryption is enabled (line above sets the full cmdline).
KERNEL_OPTS="$KERNEL_OPTS quiet splash loglevel=3 systemd.show_status=false rd.udev.log_level=3 vt.global_cursor_default=0"
# Disable zswap: the swap device is zram (already compressed RAM), so zswap in
# front of it would double-compress pages (zswap -> zram) and waste CPU.
KERNEL_OPTS="$KERNEL_OPTS zswap.enabled=0"
# NVIDIA needs DRM modeset on the cmdline too (belt-and-suspenders with the
# modprobe.d option) for Wayland/Hyprland.
[ "$GPU_NVIDIA" = 1 ] && KERNEL_OPTS="$KERNEL_OPTS nvidia_drm.modeset=1"

# /mnt/boot is the FAT32 ESP. Drop Limine's UEFI binary at BOTH the spec-defined
# vendor path (/EFI/limine) and the removable-media fallback (/EFI/BOOT/BOOTX64
# .EFI). The fallback is what makes the disk boot without an NVRAM entry — the
# efibootmgr call below often can't write NVRAM (chroot / VMs / locked firmware),
# so the fallback path is the reliable one; the NVRAM entry is a nicety.
install -d /mnt/boot/EFI/limine /mnt/boot/EFI/BOOT
cp /mnt/usr/share/limine/BOOTX64.EFI /mnt/boot/EFI/limine/BOOTX64.EFI
cp /mnt/usr/share/limine/BOOTX64.EFI /mnt/boot/EFI/BOOT/BOOTX64.EFI

# limine.conf lives on the ESP root; boot():/ resolves to that same ESP, where
# the kernel/ucode/initramfs all sit (since /boot IS the ESP). Microcode modules
# must precede the main initramfs.
# timeout: 10 — keep the Limine menu up 10s before auto-booting (user choice;
# the limine snapshot tooling only manages entries, it never rewrites this).
#
# F4 (dead-boot after a kernel update): with ENABLE_UKI=yes the first kernel
# update DELETES /boot/vmlinuz-linux + initramfs-linux.img (they're folded into
# the UKI). The OLD seed made the *first/default* manual entry `protocol: linux`
# pointing at those now-missing files, with no `default_entry:` — so once the
# UKI hook ran, the default auto-boot target dead-booted to a TTY. The previous
# post-install conversion mis-fired (ran once, no-op'd, marked applied), so the
# durable fix lives HERE in the seed:
#   * entry 1 = `protocol: efi` -> the UKI (boots once the UKI exists, which is
#     at install in the normal path, or at worst after the first kernel update).
#   * entry 2 = a `protocol: linux` fallback for the rare pre-UKI first boot
#     (snapshot/limine-update failed at install, so no UKI yet). Becomes a no-op
#     stub once the UKI exists; harmless, never the default.
#   * `default_entry: 1` pins the UKI entry as default regardless of the auto
#     entries limine appends below it on every kernel update (limine preserves
#     these manual entries + general directives verbatim across regenerations,
#     so this seed is durable — no per-update hook needed).
cat > /mnt/boot/limine.conf <<LIMINE
timeout: 10
default_entry: 1
interface_branding: HyperWebster · hyperarch

/HyperWebster · hyperarch (Arch Linux)
    protocol: efi
    path: boot():/EFI/Linux/hyperwebster_linux.efi
    cmdline: $KERNEL_OPTS

/Starman (Gaming / Steam)
    protocol: efi
    path: boot():/EFI/Linux/hyperwebster_linux.efi
    cmdline: $KERNEL_OPTS hyperwebster.starman=1

/HyperWebster (fallback kernel)
    protocol: linux
    path: boot():/vmlinuz-linux-cachyos
    cmdline: $KERNEL_OPTS
    module_path: boot():/intel-ucode.img
    module_path: boot():/amd-ucode.img
    module_path: boot():/initramfs-linux-cachyos.img

/HyperWebster (stock kernel fallback)
    protocol: linux
    path: boot():/vmlinuz-linux
    cmdline: $KERNEL_OPTS
    module_path: boot():/intel-ucode.img
    module_path: boot():/amd-ucode.img
    module_path: boot():/initramfs-linux.img
LIMINE

# Best-effort NVRAM boot entry (ignored if firmware NVRAM isn't writable here).
arch-chroot /mnt efibootmgr --create --disk "$DISK" --part 1 \
  --loader '\EFI\limine\BOOTX64.EFI' --label 'HyperWebster (Limine)' --unicode 2>/dev/null || true

# ------------------------------------------------- Btrfs + Limine snapshots ---
# Omarchy-style bootable snapshots, configured AT INSTALL TIME (this all lived
# in the first-boot script before Phase 3): limine-snapper-sync + the UKI-based
# limine-mkinitcpio-hook + snapper (root only). After this, every pacman
# transaction auto-snapshots (snap-pac), and each snapshot shows as a bootable
# entry in the Limine menu — pick one to roll back a bad update. Resilient: if
# any of this fails, the basic Limine boot set up above still works.
echo "==> Configuring Btrfs + Limine snapshots..."

# /etc/default/limine is read by the limine tools to build UKIs + boot entries.
# It must exist BEFORE the tools are installed/run. Carries the same cmdline.
cat > /mnt/etc/default/limine <<LIMINE_DEFAULT
TARGET_OS_NAME="HyperWebster"
ESP_PATH="/boot"
KERNEL_CMDLINE[default]+="$KERNEL_OPTS"
ENABLE_UKI=yes
CUSTOM_UKI_NAME="hyperwebster"
ENABLE_LIMINE_FALLBACK=yes
FIND_BOOTLOADERS=yes
BOOT_ORDER="*, *fallback, Snapshots"
MAX_SNAPSHOT_ENTRIES=5
SNAPSHOT_FORMAT_CHOICE=5
LIMINE_DEFAULT

# btrfs-overlayfs initramfs hook — lets Limine boot a read-only snapshot.
# NB: written as a FULL HOOKS= line (current hooks + btrfs-overlayfs). The
# NVIDIA kms-strip override is 20-* so it still applies after this (10-*).
cur_hooks="$(grep '^HOOKS=' /mnt/etc/mkinitcpio.conf | sed 's/^HOOKS=(//; s/)$//')"
if ! grep -qw btrfs-overlayfs <<<"$cur_hooks"; then
  install -d -m 755 /mnt/etc/mkinitcpio.conf.d
  echo "HOOKS=($cur_hooks btrfs-overlayfs)" > /mnt/etc/mkinitcpio.conf.d/10-hyperwebster-btrfs.conf
fi

# The snapshot tools come PREBUILT from the omarchy repo (bundled in the
# offline repo) — installed in a second pacstrap now that their config exists.
# KEEP IN SYNC with LIMINE_TOOLS in the builder.
nsi_phase "Installing snapshot + boot tooling"
pacstrap -C /tmp/hyperwebster-pacman.conf /mnt limine-snapper-sync limine-mkinitcpio-hook

# snapper "root" config. /.snapshots is already a mounted @snapshots subvol,
# which collides with snapper create-config (it wants to make that subvol) —
# so do the documented dance: unmount, let snapper create its own, delete it,
# then remount our @snapshots. --no-dbus because there's no snapperd in chroot.
SNAPSHOTS_OK=0
if umount /mnt/.snapshots \
   && rm -rf /mnt/.snapshots \
   && arch-chroot /mnt snapper --no-dbus -c root create-config / \
   && arch-chroot /mnt btrfs subvolume delete /.snapshots \
   && mkdir /mnt/.snapshots \
   && mount -o "$BTRFS_OPTS,subvol=@snapshots" "$BTRFS_DEV" /mnt/.snapshots \
   && chmod 750 /mnt/.snapshots; then
  # Root-only, keep 5, no timeline (pre/post pacman snapshots via snap-pac).
  arch-chroot /mnt snapper --no-dbus -c root set-config \
    NUMBER_LIMIT=5 NUMBER_LIMIT_IMPORTANT=5 \
    TIMELINE_CREATE=yes TIMELINE_CLEANUP=yes \
    TIMELINE_LIMIT_HOURLY=10 TIMELINE_LIMIT_DAILY=7 \
    TIMELINE_LIMIT_WEEKLY=0 TIMELINE_LIMIT_MONTHLY=0 TIMELINE_LIMIT_YEARLY=0 || true
  arch-chroot /mnt systemctl enable snapper-timeline.timer snapper-cleanup.timer 2>/dev/null || true
  arch-chroot /mnt btrfs quota disable / 2>/dev/null || true   # qgroup accounting is a perf drag
  arch-chroot /mnt systemctl enable limine-snapper-sync.service || true
  SNAPSHOTS_OK=1
  echo "    Snapshots configured."
else
  echo "    snapper setup failed — snapshots disabled (basic Limine boot unaffected)."
fi

# Rebuild the initramfs once, now that Plymouth, any NVIDIA overrides and the
# btrfs-overlayfs hook are all in place — then let the limine tooling generate
# the UKIs and the final boot entries.
# Full path: limine-mkinitcpio-hook ships a /usr/local/bin/mkinitcpio wrapper
# that PROMPTS [Y/n] after -P ("run limine-mkinitcpio now?") — an interactive
# blocker mid-install. limine-update below regenerates the entries anyway.
nsi_phase "Building the boot image"
arch-chroot /mnt /usr/bin/mkinitcpio -P
if [ "$SNAPSHOTS_OK" = 1 ]; then
  if arch-chroot /mnt limine-update; then
    echo "    Limine UKI entries generated."
  else
    echo "    limine-update failed — basic Limine boot still works."
  fi
fi

# ---------------------------------------------------------------- firewall ---
# Default deny inbound, allow outbound (a desktop needs no open inbound ports).
# ufw in a chroot can't apply rules to netfilter and returns non-zero on some
# versions — tolerate that; ENABLED=yes in ufw.conf + the enabled service make
# the policy apply at boot.
echo "==> Configuring firewall (ufw)..."
arch-chroot /mnt ufw default deny incoming  || true
arch-chroot /mnt ufw default allow outgoing || true
# omarchy-send / LocalSend protocol (TCP transfers + UDP discovery).
arch-chroot /mnt ufw allow 53317 || true
# mDNS responses (Avahi: .local resolution, printer/device discovery).
arch-chroot /mnt ufw allow 5353/udp || true
sed -i 's/^ENABLED=no/ENABLED=yes/' /mnt/etc/ufw/ufw.conf 2>/dev/null || true
arch-chroot /mnt systemctl enable ufw.service || true

echo "==> Writing hostname / hosts..."
echo "$HOSTNAME" > /mnt/etc/hostname
cat > /mnt/etc/hosts <<HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
HOSTS

echo "==> Creating user $USERNAME..."
# video/audio/input groups for a desktop session; wheel for sudo.
arch-chroot /mnt useradd -m -G wheel,video,audio,input -s /bin/bash "$USERNAME"
printf 'root:%s\n%s:%s\n' "$USER_PW" "$USERNAME" "$USER_PW" | arch-chroot /mnt chpasswd

# ----------------------------------------------------------- ssh handoff ----
# SSH is OPTIONAL on a desktop. If the build host baked a public key we install
# it and enable sshd (handy for remote rescue / setup), opening 22 in ufw.
# Otherwise sshd stays disabled — this is a desktop, not a server.
if [ -f /root/master.pub ]; then
  echo "==> Installing master SSH key for $USERNAME + enabling sshd..."
  install -m 700 -d "/mnt/home/$USERNAME/.ssh"
  install -m 600 /root/master.pub "/mnt/home/$USERNAME/.ssh/authorized_keys"
  arch-chroot /mnt chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.ssh"
  install -m 755 -d /mnt/etc/ssh/sshd_config.d
  cat > /mnt/etc/ssh/sshd_config.d/10-key-only.conf <<'SSHD'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
SSHD
  arch-chroot /mnt systemctl enable sshd.service || true
  arch-chroot /mnt ufw allow 22/tcp || true
else
  echo "    (no /root/master.pub on the ISO — sshd left disabled)"
fi

# ------------------------------------------------- online repos (post-boot) --
# The INSTALLED system uses the normal online mirrors, not the install media.
# The archiso live mirrorlist is reflector-generated only when online — on an
# offline install it can be empty/commented, so write a sane default the user
# can refine later. NB: nothing is synced yet; the user's first package
# operation should be `sudo pacman -Syu`.
echo "==> Writing pacman mirrorlist for the installed system..."
cat > /mnt/etc/pacman.d/mirrorlist <<'MIRROR'
## HyperWebster default mirror (geo-routed). Refine with reflector if you like:
##   sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
MIRROR

# The omarchy repo serves PREBUILT updates for the Limine snapshot tools
# (otherwise they rebuild via a ~530MB GraalVM toolchain from the AUR).
# NB: SigLevel is Optional TrustAll (unsigned) — same as Omarchy uses; it means
# trusting omarchy's binaries. Only the two limine-* packages come from it.
echo "==> Adding omarchy repo (prebuilt Limine snapshot tool updates)..."
cat >> /mnt/etc/pacman.conf <<'OMARCHY_REPO'

[omarchy]
SigLevel = Optional TrustAll
Server = https://pkgs.omarchy.org/edge/$arch
OMARCHY_REPO

# Enable [multilib] (layer change 15 — gaming enablement): the lib32-* deps
# Steam/gaming installers (DeckShift) need live there. Uncomments ONLY the
# [multilib] block (leaves [multilib-testing] alone). Nothing is synced here —
# the install is offline; the user's first `pacman -Syu` pulls the db.
echo "==> Enabling [multilib] repo in the installed system..."
sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /mnt/etc/pacman.conf

# ------------------------------------------------ CachyOS kernel (default OOB) -
# linux-cachyos is pacstrapped from the offline repo; stock linux stays as a
# fallback Limine entry. Bootstrap the CachyOS pacman repos now (vendored
# tarball — no network) so the installed system updates from CachyOS mirrors
# once online. Userspace -Suu conversion is deferred to `enable` / the toggle.
echo "==> Bootstrapping CachyOS repos (default linux-cachyos kernel)..."
install -m 755 "$HYPERWEBSTER_PAYLOAD/vendor/hyperwebster-cachy-repo" /mnt/usr/local/bin/hyperwebster-cachy-repo
CACHY_TIER=none
if h=$(/lib/ld-linux-x86-64.so.2 --help 2>/dev/null); then
  if grep -q "x86-64-v4 (supported" <<<"$h"; then CACHY_TIER=v4
  elif grep -q "x86-64-v3 (supported" <<<"$h"; then CACHY_TIER=v3; fi
fi
if [ "$CACHY_TIER" != none ] && [ -f "$HYPERWEBSTER_PAYLOAD/vendor/cachyos-repo.tar.xz" ]; then
  cp "$HYPERWEBSTER_PAYLOAD/vendor/cachyos-repo.tar.xz" /mnt/root/cachyos-repo.tar.xz
  if arch-chroot /mnt env HYPERWEBSTER_OFFLINE=1 HYPERWEBSTER_CACHY_TARBALL=/root/cachyos-repo.tar.xz \
      /usr/local/bin/hyperwebster-cachy-repo bootstrap "$CACHY_TIER"; then
    echo "    CachyOS repos bootstrapped (x86-64-$CACHY_TIER)."
  else
    echo "    WARNING: CachyOS repo bootstrap failed — Settings toggle can enable later."
  fi
  rm -f /mnt/root/cachyos-repo.tar.xz
else
  echo "    (CPU below x86-64-v3 or vendored tarball missing — stock kernel only)"
fi

# ---------------------------------------------------------- zram swap --------
# A desktop with NO swap OOM-kills heavy workloads; zram gives compressed
# in-RAM swap (no disk partition needed). zram-generator is a systemd
# generator: the package + this config auto-activate systemd-zram-setup@zram0
# at boot, no explicit enable needed.
echo "==> Configuring zram swap..."
cat > /mnt/etc/systemd/zram-generator.conf <<'ZRAM'
[zram0]
zram-size = min(ram, 8192)
compression-algorithm = zstd
ZRAM
chmod 644 /mnt/etc/systemd/zram-generator.conf

# ------------------------------------- CachyOS-derived performance tweaks ----
# Cherry-picked from CachyOS-Settings (github.com/CachyOS/CachyOS-Settings),
# same borrow-the-method approach as the chwd GPU detection: a curated subset
# of their sysctl + udev rules, vendored as plain text (no CachyOS repos or
# kernel). swappiness=100 is correct WITH zram (compressed swap is cheap).
echo "==> Applying CachyOS-derived performance tweaks..."
cat > /mnt/etc/sysctl.d/99-hyperwebster-performance.conf <<'SYSCTL'
# HyperWebster — desktop responsiveness tweaks (curated from CachyOS-Settings).
kernel.nmi_watchdog = 0
kernel.split_lock_mitigate = 0
vm.max_map_count = 2147483642
vm.swappiness = 100
vm.vfs_cache_pressure = 50
# With zram (RAM-fast, per-page decompression) swap read-ahead just wastes CPU,
# so disable it (Arch Wiki / Fedora recommend page-cluster=0 with zram).
vm.page-cluster = 0
net.ipv4.tcp_fastopen = 3
SYSCTL
cat > /mnt/etc/udev/rules.d/60-ioschedulers.rules <<'IOSCHED'
# HyperWebster — I/O scheduler per device type (from CachyOS-Settings):
# NVMe -> none, SATA/eMMC SSD -> mq-deadline, rotational -> bfq.
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
IOSCHED

# ---------------------------------------------- ~/.local/bin on PATH --------
# Put ~/.local/bin onto every login shell's PATH so user-installed binaries are
# runnable without manual PATH edits. /etc/profile.d/*.sh is sourced by
# /etc/profile for any login shell, before user dotfiles.
echo "==> Adding ~/.local/bin to PATH for all login shells..."
install -d -m 755 /mnt/etc/profile.d
cat > /mnt/etc/profile.d/local-bin.sh <<'PROFILE_LOCAL_BIN'
# Add ~/.local/bin to PATH for login shells (idempotent).
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) [ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH" ;;
esac
PROFILE_LOCAL_BIN
chmod 644 /mnt/etc/profile.d/local-bin.sh

# --------------------------------------------------------------- SDDM --------
# Display manager: SDDM (layer change 16, REQUIRED — DeckShift's
# desktop<->gaming session switching rewrites SDDM config + restarts it;
# greetd/tuigreet couldn't do this). Password greeter, NO autologin baked —
# DeckShift manages its own autologin/session entries post-install (change 17,
# opt-in). Canonical source: the layer's display-manager-sddm/
# sddm-10-hyperwebster.conf; mirrored here to keep the installer self-contained.
echo "==> Writing + enabling SDDM..."
install -d -m 755 /mnt/etc/sddm.conf.d
cat > /mnt/etc/sddm.conf.d/10-hyperwebster.conf <<'SDDMCONF'
# HyperWebster SDDM config (installed to /etc/sddm.conf.d/10-hyperwebster.conf).
[General]
# X11 greeter — the reliable, well-trodden path (needs xorg-server). The Hyprland
# SESSION still runs on Wayland; only SDDM's own greeter uses X here.
# For an X-free image instead, use the Wayland greeter:
#   DisplayServer=wayland
#   [Wayland]
#   CompositorCommand=weston --shell=kiosk   (adds `weston` to the image)
DisplayServer=x11
Numlock=on

[Users]
# The desktop session to prefer. hyprland-uwsm.desktop launches Hyprland through
# uwsm exactly like the old greetd config — keep this (NOT plain hyprland.desktop),
# or caelestia's uwsm/systemd-managed session env won't apply.
# (SDDM remembers the last-used session per user; DeckShift overrides this when
#  switching to/from its Gamescope gaming session.)
SDDMCONF
chmod 644 /mnt/etc/sddm.conf.d/10-hyperwebster.conf
# Seed SDDM's remembered last user/session so the very first greeter already
# preselects the uwsm-managed Hyprland session (hyprland-uwsm.desktop — the
# same canonical uwsm launch the old tuigreet --cmd used; plain
# hyprland.desktop would lose caelestia's uwsm/systemd-managed session env).
# SDDM rewrites this file itself after every login. mkdir -p (not install -d):
# the sddm package owns /var/lib/sddm with its own ownership/mode — don't touch.
mkdir -p /mnt/var/lib/sddm
cat > /mnt/var/lib/sddm/state.conf <<SDDMSTATE
[Last]
Session=/usr/share/wayland-sessions/hyprland-uwsm.desktop
User=$USERNAME
SDDMSTATE
# 644, NOT 600: the GREETER (running as the 'sddm' user) reads this file to
# prefill the last user/session — 600 root:root leaves the username field
# empty on first boot (caught in VM cert). SDDM itself writes it 644.
chmod 644 /mnt/var/lib/sddm/state.conf
arch-chroot /mnt systemctl enable sddm.service

# ------------------------------------------------- caelestia desktop ---------
# Lay down the complete caelestia desktop for the user AT INSTALL TIME, exactly
# replicating what upstream's install.fish does on a live system (investigated
# against a completed install): dotfiles clone in ~/.local/share/caelestia,
# symlinks from ~/.config into it, the colour scheme seeded, plus the HyperWebster
# restraint config and the workspace-overview sidecar. The caelestia PACKAGES
# (shell/cli/meta + deps) were already installed by pacstrap from the bundled
# repo.
echo "==> Installing caelestia desktop for $USERNAME (offline)..."
USER_HOME="/home/$USERNAME"
M_HOME="/mnt$USER_HOME"

install -d -m 755 "$M_HOME/.local/share" "$M_HOME/.config"
tar -xzf "$HYPERWEBSTER_PAYLOAD/vendor/caelestia-dotfiles.tar.gz" -C "$M_HOME/.local/share"
chmod u+x "$M_HOME/.local/share/caelestia/hypr/scripts/wsaction.fish" 2>/dev/null || true

# The symlink set upstream install.fish creates (targets are the FINAL paths
# as seen on the booted system, so they dangle here in the live env — fine).
for link in hypr foot fish uwsm btop; do
  [ -e "$M_HOME/.local/share/caelestia/$link" ] || continue
  ln -sfn "$USER_HOME/.local/share/caelestia/$link" "$M_HOME/.config/$link"
done
[ -e "$M_HOME/.local/share/caelestia/starship.toml" ] \
  && ln -sfn "$USER_HOME/.local/share/caelestia/starship.toml" "$M_HOME/.config/starship.toml"

# --- HyperWebster restraint config (Phase 2) ---------------------------------------
# Overrides on top of caelestia's defaults. Pure config — Caelestia's own
# token/appearance system reads these; no shell code is touched, and deleting
# any file restores stock caelestia. Canonical source: the hyperwebster-shell config
# repo (hyperwebster/config/); mirrored here to keep the installer self-contained.
echo "==> Applying HyperWebster desktop restraint config..."
install -d -m 755 "$M_HOME/.config/caelestia"
# Restrained design tokens: SQUARE corners (rounding ramp zeroed — redesign goal;
# the 77 Tokens.rounding.* bindings honour these, appearance.rounding.scale does
# not feed them; rounding.full omitted so genuine circles stay), tighter
# spacing/padding, denser fonts, snappier animations (overrides Caelestia's
# config-driven Tokens system).
cat > "$M_HOME/.config/caelestia/shell-tokens.json" <<'HYPERWEBSTER_TOKENS'
{
  "appearance": {
    "rounding": { "extraSmall": 0, "small": 0, "medium": 0, "large": 0, "largeIncreased": 0, "extraLarge": 0, "extraLargeIncreased": 0, "extraExtraLarge": 0 },
    "spacing": { "extraSmall": 3, "small": 6, "medium": 9, "large": 13, "largeIncreased": 16, "extraLarge": 22, "extraLargeIncreased": 26, "extraExtraLarge": 38 },
    "padding": { "extraSmall": 3, "small": 6, "medium": 9, "large": 13, "largeIncreased": 16, "extraLarge": 22, "extraLargeIncreased": 26, "extraExtraLarge": 38 },
    "fontSize": { "small": 10, "smaller": 11, "normal": 12, "larger": 14, "large": 16, "extraLarge": 24 },
    "animDurations": { "small": 80, "normal": 130, "large": 210, "extraLarge": 300, "expressiveFastSpatial": 130, "expressiveDefaultSpatial": 200, "expressiveSlowSpatial": 280, "expressiveFastEffects": 70, "expressiveDefaultEffects": 110, "expressiveSlowEffects": 160 }
  }
}
HYPERWEBSTER_TOKENS
# Appearance restraint + config-level cuts: opaque panels, Material Symbols
# Outlined icons, drop the Performance/Weather dashboard tabs, visualiser off.
# F9: HyperWebster launches Hyprland via uwsm, but caelestia's built-in default
# session.commands.logout targets a plain (non-uwsm) session, so the session
# menu's Logout button was a no-op. `uwsm stop` is the documented way to end a
# uwsm session (drops back to SDDM); shutdown/reboot/hibernate use systemctl and
# are left at caelestia's defaults.
cat > "$M_HOME/.config/caelestia/shell.json" <<'HYPERWEBSTER_SHELL'
{
  "appearance": {
    "transparency": { "enabled": false },
    "rounding": { "scale": 0 },
    "font": {
      "headline": { "family": "JetBrainsMono Nerd Font" },
      "title": { "family": "JetBrainsMono Nerd Font" },
      "body": { "family": "JetBrainsMono Nerd Font" },
      "label": { "family": "JetBrainsMono Nerd Font" },
      "mono": { "family": "JetBrainsMono Nerd Font" },
      "icon": { "family": "Material Symbols Outlined" }
    }
  },
  "general": {
    "apps": {
      "terminal": ["kitty"],
      "explorer": ["nautilus"]
    }
  },
  "session": {
    "commands": {
      "logout": ["uwsm", "stop"]
    }
  },
  "dashboard": { "showPerformance": false, "showWeather": true },
  "background": { "visualiser": { "enabled": false } },
  "launcher": {
    "maxShown": 8,
    "vimKeybinds": false,
    "showOnHover": false,
    "useFuzzy": {
      "apps": true,
      "actions": true,
      "schemes": false,
      "variants": false,
      "wallpapers": false
    }
  },
  "bar": {
    "entries": [
      { "id": "logo", "enabled": true },
      { "id": "workspaces", "enabled": true },
      { "id": "spacer", "enabled": true },
      { "id": "clock", "enabled": true },
      { "id": "spacer", "enabled": true },
      { "id": "statusIcons", "enabled": true },
      { "id": "tray", "enabled": true },
      { "id": "power", "enabled": true }
    ]
  }
}
HYPERWEBSTER_SHELL
# Flatten the Hyprland glassmorphism (blur/shadow off, solid windows, tighter
# corners + gaps). Sourced by caelestia's hyprland.conf right after variables.conf.
cat > "$M_HOME/.config/caelestia/hypr-vars.conf" <<'HYPERWEBSTER_HYPRVARS'
# HyperWebster restraint — flatten Caelestia's glassmorphism (deleting restores stock).
# Default applications (caelestia's stock picks aren't installed: zen-browser/
# codium/thunar — point the Super-key app binds at what HyperWebster actually ships).
$terminal = kitty
$browser = chromium
$editor = gnome-text-editor
$fileExplorer = nautilus
$blurEnabled = false
$blurPopups = false
$blurInputMethods = false
$shadowEnabled = false
$windowOpacity = 1.0
$windowRounding = 0
$workspaceGaps = 10
$windowGapsIn = 4
$windowGapsOut = 8
$singleWindowGapsOut = 12
HYPERWEBSTER_HYPRVARS

# --- Workspace Overview (standalone sidecar) ----------------------------------
# quickshell-overview runs as its OWN qs instance next to caelestia, toggled by
# Super+Tab over IPC. Caelestia's shell is never modified (no fork/package).
echo "==> Installing workspace Overview (sidecar)..."
install -d -m 755 "$M_HOME/.config/quickshell"
tar -xzf "$HYPERWEBSTER_PAYLOAD/vendor/quickshell-overview.tar.gz" -C "$M_HOME/.config/quickshell"
# theme-match caelestia + low-RAM event previews + no blur
cat > "$M_HOME/.config/quickshell/overview/config.json" <<'HYPERWEBSTER_OV_CFG'
{
  "appearance": { "colorSource": "caelestia" },
  "overview": { "previewMode": "event", "previewsEnabled": true, "closeOnFocusLoss": true, "hideEmptyRows": true, "effects": { "enableBlur": false, "enableBackdrop": false, "glassMode": false } }
}
HYPERWEBSTER_OV_CFG

# --- omarchy-send (LAN file transfer, LocalSend-compatible) -------------------
# Vendored release binary; system-wide so every user gets it. The desktop entry
# opens the TUI in a floating kitty (TUI.float class — float rule above).
echo "==> Installing omarchy-send..."
install -m 755 "$HYPERWEBSTER_PAYLOAD/vendor/omarchy-send" /mnt/usr/local/bin/omarchy-send
install -d -m 755 /mnt/usr/share/applications /mnt/usr/share/icons/hicolor/scalable/apps
cat > /mnt/usr/share/icons/hicolor/scalable/apps/omarchy-send.svg <<'OMS_ICON'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <rect width="256" height="256" rx="56" fill="#16161e"/>
  <path d="M214 42 L42 114 L110 142 Z" fill="#7aa2f7"/>
  <path d="M214 42 L110 142 L130 214 L158 166 Z" fill="#5a7fd6"/>
</svg>
OMS_ICON
cat > /mnt/usr/share/applications/omarchy-send.desktop <<'OMS_DESKTOP'
[Desktop Entry]
Name=Omarchy-Send
Comment=Send & receive files over the LAN (LocalSend-compatible)
Exec=kitty --class TUI.float -e omarchy-send
Icon=omarchy-send
Terminal=false
Type=Application
Categories=Network;FileTransfer;
Keywords=localsend;share;transfer;airdrop;
OMS_DESKTOP

# --- OS theme wallpapers -------------------------------------------------------
# The user's own Moebius-style art set. caelestia's dynamic Material scheme is
# generated FROM the default wallpaper (foam-sea.png, change 18) in the scheme
# step below.
echo "==> Installing HyperWebster wallpapers..."
install -d -m 755 "$M_HOME/Pictures/Wallpapers"
tar -xf "$HYPERWEBSTER_PAYLOAD/vendor/hyperwebster-wallpapers.tar" -C "$M_HOME/Pictures/Wallpapers"

# Chromium on Wayland: pick the ozone backend automatically (native Wayland
# under Hyprland instead of XWayland).
cat > /mnt/etc/chromium-flags.conf <<'CHROMIUM_FLAGS'
--ozone-platform-hint=auto
CHROMIUM_FLAGS
# autostart the sidecar + toggle bind via caelestia's last-sourced user hook.
# Overview lives on Super+GRAVE (not Tab): the Omarchy keymap appended below
# puts next-workspace on Super+Tab — see dev-docs/BUILDER-HANDOFF.md.
cat > "$M_HOME/.config/caelestia/hypr-user.conf" <<'HYPERWEBSTER_HYPRUSER'
# HyperWebster — overview sidecar autostart + keybind (deleting restores stock).
exec-once = qs -c overview -d
bind = Super, Grave, exec, qs ipc -c overview call overview toggle

# F10: open Caelestia Settings (nexus). Super+Alt+Space is free (HyperWebster moved
# the old float-toggle to Super+T). caelestia:nexus is the registered global
# shortcut that opens the Settings window.
bind = Super+Alt, Space, global, caelestia:nexus

# hyprmoncfg writes monitor layout/resolution + workspace assignments here
# (the files are pre-created empty so Hyprland never warns about the source;
# hyprmoncfg refuses to write monitors.conf unless it is sourced).
source = ~/.config/hypr/monitors.conf
source = ~/.config/hypr/workspaces.conf

# omarchy-send launches in a floating terminal window
windowrule = float true, match:class TUI\.float
windowrule = size 1100 700, match:class TUI\.float

# Passwordless-sudo password prompt (Settings -> Services). Dedicated class +
# centered/pinned floating window; SudoToggleRow also dispatches `focuswindow` so
# the prompt grabs keyboard focus (without it the prompt missed keystrokes and
# three blank tries tripped pam_faillock — hardware bug 2026-06-20).
# NB: `stayfocused` is NOT valid in Hyprland 0.55's match: windowrule grammar
# (errors at parse time), so focus is forced from the shell via hyprctl instead.
windowrule = float on, match:class hyperwebster-sudo
windowrule = size 640 220, match:class hyperwebster-sudo
windowrule = center on, match:class hyperwebster-sudo
windowrule = pin on, match:class hyperwebster-sudo

# polkit auth agent — none ran out of the box, so GUI privilege prompts (pkexec,
# nm-connection-editor system connections, etc.) silently failed. Non-fatal.
exec-once = systemctl --user start hyprpolkitagent.service
HYPERWEBSTER_HYPRUSER
# Keyboard layout from the installer prompt (appended unquoted — $XKB_LAYOUT).
{
  echo ''
  echo '# Keyboard layout chosen at install'
  echo "input:kb_layout = $XKB_LAYOUT"
} >> "$M_HOME/.config/caelestia/hypr-user.conf"

# F1-B / F11-2: the hypr-user.conf override above was NOT winning — caelestia's
# stock hypr/hyprland/input.conf hardcodes `kb_layout = us` and is sourced such
# that it overrides the variable set above, so the Wayland session AND the lock
# surface came up US-layout on a GB system (mistyped password symbols were F1's
# original trigger). Set the chosen layout in that authoritative file too. The
# dotfiles are extracted once at install (not a package), so this is durable.
# ~/.config/hypr is a symlink into the clone; edit the real file under it.
INPUT_CONF="$M_HOME/.local/share/caelestia/hypr/hyprland/input.conf"
# Fall back to locating whichever file in the hypr tree carries kb_layout, in
# case upstream moves it (keeps the fix working across caelestia layout changes).
if [ ! -f "$INPUT_CONF" ]; then
  INPUT_CONF=$(grep -rlE '^[[:space:]]*kb_layout[[:space:]]*=' \
    "$M_HOME/.local/share/caelestia/hypr/" 2>/dev/null | head -n1)
fi
if [ -n "$INPUT_CONF" ] && [ -f "$INPUT_CONF" ]; then
  if grep -qE '^[[:space:]]*kb_layout[[:space:]]*=' "$INPUT_CONF"; then
    sed -i "s|^\([[:space:]]*kb_layout[[:space:]]*=[[:space:]]*\).*|\1$XKB_LAYOUT|" "$INPUT_CONF"
  else
    printf '\n# Keyboard layout chosen at install (HyperWebster)\ninput {\n    kb_layout = %s\n}\n' "$XKB_LAYOUT" >> "$INPUT_CONF"
  fi
  echo "    Hyprland kb_layout set to $XKB_LAYOUT in input.conf"
else
  echo "    NOTE: caelestia input.conf not found — relying on hypr-user.conf kb_layout only"
fi

# Empty targets for hyprmoncfg (live in the dotfiles clone — ~/.config/hypr
# is a symlink into it; hyprmoncfg follows the symlink when saving).
touch "$M_HOME/.local/share/caelestia/hypr/monitors.conf" \
      "$M_HOME/.local/share/caelestia/hypr/workspaces.conf"

# kitty: bash is the default shell (HyperWebster layer change 2 — Omarchy setup);
# ~/.bashrc applies caelestia's colour-scheme escape sequences at terminal
# start (cat sequences.txt), so kitty gets themed the same way fish did.
install -d -m 755 "$M_HOME/.config/kitty"
cat > "$M_HOME/.config/kitty/kitty.conf" <<'HYPERWEBSTER_KITTY'
# HyperWebster defaults — kitty is the default terminal ($terminal in hypr-vars.conf).
shell bash
font_family JetBrainsMono Nerd Font
font_size 12.0
enable_audio_bell no
confirm_os_window_close 0
HYPERWEBSTER_KITTY

# fastfetch: the HyperWebster layout (Hardware / Software / Age-Uptime boxes + the
# HyperWebster logo). Shipped as a real config — NOT symlinked into the caelestia
# clone (fastfetch was dropped from the symlink loop above) so it overrides the
# dotfiles default. The logo lives beside it; config.jsonc points at it.
install -d -m 755 "$M_HOME/.config/fastfetch"
install -m 644 "$HYPERWEBSTER_PAYLOAD/vendor/fastfetch-config.jsonc" \
  "$M_HOME/.config/fastfetch/config.jsonc"
install -m 644 "$HYPERWEBSTER_PAYLOAD/vendor/fastfetch-logo.txt" \
  "$M_HOME/.config/fastfetch/logo.txt"

# ---------------------------------------------- HyperWebster layer (changes 1-26) --
# The "os updates" rounds, baked in at install time: keybind cheatsheet, bash
# default shell, hyperwebster-update mechanism, yay+Shelly store, Omarchy default
# keybindings, omadots developer polish, hyprmoncfg, settings Updates page,
# system polish (1-9); universal copy/paste, screenshots, the launcher/
# dashboard/monitor fix-ups, gaming enablement, SDDM + themed greeter (10-16,
# 18-19); Wi-Fi wrong-password recovery, monitor profile hot-load, yay-menu
# pre-answers, tidied cheatsheet, CLIAmp music player, Settings Additions
# page, uuctl hidden (20-26, the 2026-06-12 hardware-test round). Change 17
# (deckshift-login) SHIPS in the tree but is NOT applied — gaming is opt-in
# post-install. The packages came from pacstrap; everything else comes from
# the layer tree itself, so the ISO and a live-updated box are identical.
# Conf fragments are appended FROM the extracted tree so they cannot drift.
nsi_phase "Applying the HyperWebster layer"
echo "==> Installing HyperWebster layer (os-updates round)..."
tar -xzf "$HYPERWEBSTER_PAYLOAD/vendor/hyperwebster-layer.tar.gz" -C "$M_HOME/.local/share"
LAYER="$M_HOME/.local/share/hyperwebster"
chmod +x "$LAYER/hyperwebster-update/bin/hyperwebster-update" "$LAYER/hyperwebster-update/migrations/"*.sh

# On-box management skill: a fresh Claude Code on this machine auto-discovers
# the `hyperwebster` skill (its description is surfaced in the available-skills list)
# and can help the USER configure / fix / maintain their install — strictly
# end-user system management, NOT the dev/QA test protocol. The skill's
# references/ are copied from the layer's single-source docs at install time, so
# they track the build and can never drift (the staleness trap the frozen
# ONBOX-TEST-NOTES.md fell into). The originals stay in ~/.local/share/hyperwebster/.
SKILL_DIR="$M_HOME/.claude/skills/hyperwebster"
install -d -m 755 "$SKILL_DIR/references"
install -m 644 "$LAYER/onbox-skill/SKILL.md"   "$SKILL_DIR/SKILL.md"
install -m 644 "$LAYER/ONBOX-AI-NOTES.md"       "$SKILL_DIR/references/ONBOX-AI-NOTES.md"
install -m 644 "$LAYER/HyperWebster-keybindings.md" "$SKILL_DIR/references/HyperWebster-keybindings.md"

# Commands onto ~/.local/bin (already on PATH via the profile drop above).
# hyperwebster-update stays a symlink INTO the layer tree — it locates its
# migrations by resolving its own path.
install -d -m 755 "$M_HOME/.local/bin"
install -m 755 "$LAYER/hyperwebster-keybinds" "$LAYER/hyperwebster-keybinds-gen" \
  "$LAYER/system-polish/hyperwebster-webapp-install" \
  "$LAYER/system-polish/hyperwebster-webapp-remove" \
  "$LAYER/system-polish/hyperwebster-welcome" \
  "$LAYER/updates-panel/hyperwebster-update-check" \
  "$LAYER/super-clipboard/super-copy" \
  "$LAYER/super-clipboard/super-paste" \
  "$LAYER/screenshots/hyperwebster-screenshot" \
  "$LAYER/omarchy-extras/hyperwebster-share" \
  "$LAYER/omarchy-extras/hyperwebster-transcode" \
  "$LAYER/omarchy-extras/hyperwebster-ocr-capture" \
  "$LAYER/omarchy-extras/hyperwebster-nightlight-toggle" \
  "$LAYER/omarchy-extras/omarchy-transcode" \
  "$LAYER/additions-installer/hyperwebster-additions" \
  "$LAYER/app-theme-awareness/hyperwebster-app-theme-sync" \
  "$LAYER/kernel-reboot-notify/hyperwebster-reboot-check" \
  "$LAYER/btrfs-snapshot-manager/hyperwebster-snapshots" \
  "$LAYER/zephyr-polish/hyperwebster-zephyr-polish" \
  "$LAYER/distro-tools/hyperwebster-maint" \
  "$M_HOME/.local/bin/"
# Omarchy CLI shims (change 15) — let Omarchy-targeted gaming installers
# (DeckShift) run on HyperWebster: omarchy-pkg-add -> yay, steam installer, NVIDIA
# GSP probes, restart-walker no-op.
install -m 755 "$LAYER/gaming-enablement/omarchy-pkg-add" \
  "$LAYER/gaming-enablement/omarchy-install-gaming-steam" \
  "$LAYER/gaming-enablement/omarchy-hw-nvidia-gsp" \
  "$LAYER/gaming-enablement/omarchy-hw-nvidia-without-gsp" \
  "$LAYER/gaming-enablement/omarchy-restart-walker" \
  "$M_HOME/.local/bin/"
ln -sf "$USER_HOME/.local/share/hyperwebster/hyperwebster-update/bin/hyperwebster-update" \
  "$M_HOME/.local/bin/hyperwebster-update"

# --- change 27 (xdg-terminal-exec-handler, finding F2): app2unit hardcodes its
# terminal handler to `xdg-terminal-exec`, which HyperWebster never shipped, so any
# Terminal=true desktop entry (and app2unit -T) failed with a critical
# notification. Ship a small shim on PATH that launches the configured terminal
# ($TERMINAL, else kitty), plus a system xdg-terminals.list pointing at kitty.
# (The shim self-removes if the real freedesktop package ever lands in a system
# bin — see the component installer.)
install -m 755 "$LAYER/xdg-terminal-exec-handler/xdg-terminal-exec" \
  "$M_HOME/.local/bin/xdg-terminal-exec"
install -d -m 755 /mnt/etc/xdg
printf 'kitty.desktop\n' > /mnt/etc/xdg/xdg-terminals.list
chmod 644 /mnt/etc/xdg/xdg-terminals.list

# Mark every shipped migration as applied — the layer is baked in, so the
# user's first `hyperwebster-update` must report "0 new migrations" (they are
# idempotent, but re-running needs network/sudo and is noisy). Do NOT create
# the `welcomed` stamp: the first-login welcome notice must fire.
install -d -m 755 "$M_HOME/.local/state/hyperwebster"
for m in "$LAYER/hyperwebster-update/migrations/"*.sh; do
  basename "$m"
done > "$M_HOME/.local/state/hyperwebster/applied"

# --- change 29 (limine-uki-dead-entry, finding F4, BLOCKER): FIXED IN THE SEED.
# The dead-boot is now prevented at the source — the seeded limine.conf above
# ships a `protocol: efi` -> UKI entry as entry 1 with `default_entry: 1`, plus a
# `protocol: linux` fallback as entry 2. Limine preserves these manual entries +
# `default_entry` verbatim across every kernel-update regeneration, so the
# default boot target can never become the dead vmlinuz entry. No post-install
# conversion is needed (the old one-shot conversion mis-fired on 20260613). The
# limine-uki-dead-entry/ component is kept in the layer ONLY as a manual repair
# tool for boxes installed from a pre-fix ISO; it is NOT run at install anymore.

# --- change 2: default shell bash, matching Omarchy. The fish PACKAGE stays
# (caelestia-meta hard-depends on it) and the hypr config keeps calling the
# *.fish script paths — replaced with bash ports under the same filenames.
echo "==> Default shell: bash (Omarchy setup)..."
install -d -m 755 "$M_HOME/.local/share/omarchy/default"
cp -a "$LAYER/fish-to-bash/bash" "$M_HOME/.local/share/omarchy/default/bash"
install -m 644 "$LAYER/fish-to-bash/bashrc" "$M_HOME/.bashrc"
install -m 755 "$LAYER/fish-to-bash/hypr-wsaction.bash" \
  "$M_HOME/.local/share/caelestia/hypr/scripts/wsaction.fish"
install -m 755 "$LAYER/fish-to-bash/hypr-configs.bash" \
  "$M_HOME/.local/share/caelestia/hypr/scripts/configs.fish"
# foot config lives in the dotfiles clone (~/.config/foot is a symlink)
sed -i 's/^shell=.*/shell=bash/' "$M_HOME/.local/share/caelestia/foot/foot.ini"
# Square corners everywhere (redesign goal): caelestia's rules.conf hardcodes
# `rounding 10` on Steam + some XWayland windows, ignoring $windowRounding=0.
# Zero them so those windows aren't the only rounded ones on the desktop.
sed -i -E 's/^(windowrule = )rounding 10,/\1rounding 0,/' \
  "$M_HOME/.local/share/caelestia/hypr/hyprland/rules.conf" 2>/dev/null || true

# --- change 6: omadots developer polish. starship/btop replace the caelestia
# symlinks made above (re-linking restores stock); git behaviors arrive via
# include.path so user identity stays out of the image; LazyVim from vendor.
echo "==> omadots developer polish..."
rm -f "$M_HOME/.config/starship.toml"
install -m 644 "$LAYER/omadots-extras/starship.toml" "$M_HOME/.config/starship.toml"
rm -f "$M_HOME/.config/btop"
install -d -m 755 "$M_HOME/.config/btop" "$M_HOME/.config/tmux" "$M_HOME/.config/git"
install -m 644 "$LAYER/omadots-extras/btop.conf" "$M_HOME/.config/btop/btop.conf"
install -m 644 "$LAYER/omadots-extras/tmux.conf" "$M_HOME/.config/tmux/tmux.conf"
install -m 644 "$LAYER/omadots-extras/omadots.gitconfig" "$M_HOME/.config/git/omadots.gitconfig"
cat > "$M_HOME/.gitconfig" <<GITINCLUDE
# HyperWebster — omadots git aliases/behaviors. Your identity goes here, per-user.
[include]
	path = $USER_HOME/.config/git/omadots.gitconfig
GITINCLUDE
tar -xzf "$HYPERWEBSTER_PAYLOAD/vendor/lazyvim-starter.tar.gz" -C "$M_HOME/.config"

# --- changes 1+4+5+7+9+10+11: keybindings + binds, appended from the layer
# tree. omarchy-keys-vars remaps the $kb* variables (hypr-vars.conf is sourced
# before keybinds.conf consumes them); the user-conf fragments land last.
# Changes 10+11 are the marked blocks from the component installers, extracted
# verbatim (markers included) so a later hyperwebster-update re-run of those
# installers detects them as already present and skips.
echo "==> Omarchy keymap + layer binds..."
{
  echo ''
  cat "$LAYER/omarchy-keys/omarchy-keys-vars.conf"
} >> "$M_HOME/.config/caelestia/hypr-vars.conf"
{
  echo ''
  cat "$LAYER/hyprland-keybinds-help.conf"
  echo ''
  cat "$LAYER/software-install/hyprland-software-install.conf"
  echo ''
  cat "$LAYER/omarchy-keys/omarchy-keys-user.conf"
  echo ''
  cat "$LAYER/omarchy-extras/omarchy-extras-keys.conf"
  echo ''
  cat "$LAYER/monitor-control/hyprland-monitor-control.conf"
  echo ''
  sed -n '/# >>> super-clipboard/,/# <<< super-clipboard/p' \
    "$LAYER/super-clipboard/install-super-clipboard.sh"
  echo ''
  sed -n '/# >>> hyperwebster screenshots/,/# <<< hyperwebster screenshots/p' \
    "$LAYER/screenshots/install-screenshots.sh"
  echo ''
  # change 24: CLIAmp marked block (float rules + Super+M launch-or-focus) —
  # shipped as a standalone conf fragment, appended VERBATIM markers included.
  cat "$LAYER/cliamp-music/hyprland-cliamp.conf"
  echo ''
  echo '# HyperWebster — one-time first-login welcome (stamps ~/.local/state/hyperwebster/welcomed)'
  echo 'exec-once = ~/.local/bin/hyperwebster-welcome'
} >> "$M_HOME/.config/caelestia/hypr-user.conf"

# --- change 11: screenshots land in ~/Pictures/Screenshots (clipboard too);
# swappy (the caelestia region/freeze annotate binds) saves to the same place.
install -d -m 755 "$M_HOME/Pictures/Screenshots" "$M_HOME/.config/swappy"
install -m 644 "$LAYER/screenshots/swappy-config" "$M_HOME/.config/swappy/config"

# --- omarchy-extras: XCompose emoji sequences + env for XWayland apps.
install -d -m 755 "$M_HOME/.config/environment.d"
{
  echo '# HyperWebster omarchy-extras — sourced from Omarchy default/xcompose'
  cat "$LAYER/omarchy-extras/xcompose"
} > "$M_HOME/.XCompose"
cat > "$M_HOME/.config/environment.d/99-hyperwebster-compose.conf" <<'COMPOSE_ENV'
# HyperWebster — Omarchy-style XCompose sequences (XWayland apps).
XCOMPOSEFILE=$HOME/.XCompose
COMPOSE_ENV

# --- changes 7+8: user services. No systemd in the chroot — enable = the
# symlink systemctl would create, targets read from each unit's [Install].
echo "==> Enabling user services (hyprmoncfgd, update check timer)..."
install -d -m 755 "$M_HOME/.config/systemd/user/default.target.wants" \
                  "$M_HOME/.config/systemd/user/timers.target.wants"
install -m 644 "$LAYER/updates-panel/hyperwebster-update-check.service" \
               "$LAYER/updates-panel/hyperwebster-update-check.timer" \
               "$M_HOME/.config/systemd/user/"
ln -sf ../hyperwebster-update-check.timer \
  "$M_HOME/.config/systemd/user/timers.target.wants/hyperwebster-update-check.timer"
ln -sf /usr/lib/systemd/user/hyprmoncfgd.service \
  "$M_HOME/.config/systemd/user/default.target.wants/hyprmoncfgd.service"
# change 12 (fix for change 7): point hyprmoncfgd at hypr-user.conf (the file
# that actually sources monitors.conf — it refuses to write otherwise) and
# gate its start until Hyprland's IPC answers (avoids a login-race error
# notification). Same flags are baked into the Super+Ctrl+H bind above.
install -d -m 755 "$M_HOME/.config/systemd/user/hyprmoncfgd.service.d"
install -m 644 "$LAYER/monitor-control-fix/hyprmoncfgd-override.conf" \
  "$M_HOME/.config/systemd/user/hyprmoncfgd.service.d/override.conf"
# change 21 (monitor-hotload): path unit watches ~/.config/hyprmoncfg/profiles
# and try-restarts hyprmoncfgd, so a plain "Save Profile" in the Super+Ctrl+H
# TUI applies live. The watched dir must exist (empty — the no-pre-seeded-
# profiles rule from change 7 still stands).
install -m 644 "$LAYER/monitor-hotload/hyprmoncfgd-rescan.path" \
               "$LAYER/monitor-hotload/hyprmoncfgd-rescan.service" \
               "$M_HOME/.config/systemd/user/"
ln -sf ../hyprmoncfgd-rescan.path \
  "$M_HOME/.config/systemd/user/default.target.wants/hyprmoncfgd-rescan.path"
install -d -m 755 "$M_HOME/.config/hyprmoncfg/profiles"

# --- change 30 (app-theme-awareness, finding F6): make external apps
# (Chrome/Electron/Firefox/GTK/Qt) follow Caelestia's light/dark mode. The sync
# script (installed to ~/.local/bin above) mirrors `caelestia scheme get` to the
# freedesktop appearance portal color-scheme + the GTK prefer-dark flag; a .path
# unit re-runs it whenever Caelestia's scheme.json changes, and .service runs it
# at login. portals.conf pins the Settings portal to gtk so the value is served.
echo "==> Enabling app-theme awareness (follow Caelestia dark/light)..."
install -m 644 "$LAYER/app-theme-awareness/hyperwebster-app-theme.service" \
               "$LAYER/app-theme-awareness/hyperwebster-app-theme.path" \
               "$M_HOME/.config/systemd/user/"
ln -sf ../hyperwebster-app-theme.path \
  "$M_HOME/.config/systemd/user/default.target.wants/hyperwebster-app-theme.path"
ln -sf ../hyperwebster-app-theme.service \
  "$M_HOME/.config/systemd/user/default.target.wants/hyperwebster-app-theme.service"
install -d -m 755 "$M_HOME/.config/xdg-desktop-portal"
install -m 644 "$LAYER/app-theme-awareness/portals.conf" \
  "$M_HOME/.config/xdg-desktop-portal/portals.conf"

# --- theme-polish: SDDM follows scheme changes; passwordless sync for wheel.
echo "==> Installing theme polish (light/dark + SDDM auto-sync)..."
arch-chroot /mnt env HYPERWEBSTER_USER_HOME="$USER_HOME" HYPERWEBSTER_INSTALL_USER="$USERNAME" \
  sh "$USER_HOME/.local/share/hyperwebster/theme-polish/install-theme-polish.sh" \
  || echo "    (theme-polish root install failed — manual sddm-theme-sync still works)"
arch-chroot /mnt runuser -u "$USERNAME" -- \
  env HOME="$USER_HOME" XDG_CONFIG_HOME="$USER_HOME/.config" \
  sh "$USER_HOME/.local/share/hyperwebster/theme-polish/install-theme-polish.sh" \
  || echo "    (theme-polish user units skipped)"

# --- starman-gaming-boot: Limine Starman entry -> gamescope session.
echo "==> Installing Starman gaming boot hook..."
arch-chroot /mnt sh "$USER_HOME/.local/share/hyperwebster/starman-gaming-boot/install-starman-gaming-boot.sh" \
  || echo "    (starman-gaming-boot install failed — Limine entry still present)"

# --- drive-automount: premount data drives under /mnt/<label>.
echo "==> Installing drive automount..."
arch-chroot /mnt sh "$USER_HOME/.local/share/hyperwebster/drive-automount/install-drive-automount.sh" \
  || echo "    (drive-automount install failed — mount data drives manually)"

# --- changes 8/25/20: Updates/Additions/Wi-Fi pages ship in nosignal-shell, rebranded
# to hyperwebster-* at ISO build (see shell-branding/) + install-time safety patch.
# Additions manifest + status cache install below; Updates timer units above.
install -d -m 755 /mnt/etc/pacman.d/hooks

# --- change 25: Additions manifest + status cache (shell QML is branded at ISO build).
echo "==> Installing Additions backend (manifest + status cache)..."
arch-chroot /mnt runuser -u "$USERNAME" -- \
  env HOME="$USER_HOME" HYPERWEBSTER_SKIP_SHELL_PATCH=1 \
  sh "$USER_HOME/.local/share/hyperwebster/additions-installer/install-additions-installer.sh" \
  || echo "    (additions-installer failed — Settings → Additions may be empty)"

# --- Shell branding safety net (patch installed QML if the on-box package predates build-time rebrand).
echo "==> Applying shell branding (About / Updates / Additions CLIs)..."
arch-chroot /mnt sh "$USER_HOME/.local/share/hyperwebster/shell-branding/install-shell-branding.sh" \
  || echo "    (shell-branding patch failed — run hyperwebster-update after boot)"

# --- Pacman hooks: nosignal-shell upgrades overwrite /etc/xdg — re-apply HyperWebster patches.
echo "==> Installing Updates / Additions / Wi-Fi shell pacman hooks..."
arch-chroot /mnt runuser -u "$USERNAME" -- env HOME="$USER_HOME" \
  sh "$USER_HOME/.local/share/hyperwebster/updates-panel/install-updates-panel.sh" \
  || echo "    (updates-panel install failed — run hyperwebster-update after boot)"
arch-chroot /mnt runuser -u "$USERNAME" -- env HOME="$USER_HOME" \
  sh "$USER_HOME/.local/share/hyperwebster/wifi-password-retry/install-wifi-password-retry.sh" \
  || echo "    (wifi-password-retry install failed — run hyperwebster-update after boot)"

# --- change 31 (kernel-reboot-notify, finding F5): a pacman PostTransaction
# hook that prints a "reboot required" reminder (and "boot the UKI entry") in
# the pacman/yay output whenever a kernel image changes, so out-of-band
# `pacman -Syu`/`yay` updates warn too. The desktop notification + state stamp
# are handled by hyperwebster-reboot-check, which hyperwebster-update calls at its end.
echo "==> Installing kernel-reboot reminder pacman hook..."
install -m 644 "$LAYER/kernel-reboot-notify/95-hyperwebster-kernel-reboot.hook" \
  /mnt/etc/pacman.d/hooks/95-hyperwebster-kernel-reboot.hook

# --- change 28 (caelestia-lock-faillock, finding F1, BLOCKER): the faillock-free
# lock-screen PAM service (assets/pam.d/caelestia) and the Pam.qml repoint
# (config: "passwd" -> "caelestia") are now BAKED INTO the pinned hyperwebster-shell
# fork (Phase 2). No patch script or pacman hook needed — the fork ships the
# correct lock auth, so a desktop screen-lock can never faillock the user out
# of their own session.

# --- change 36 (sudo-timed-nopasswd): a Settings -> Services toggle (+ CLI)
# that grants the user NOPASSWD: ALL for 15 minutes then auto-reverts (a root
# systemd timer), with a boot-clean safety net and a sudoers `visudo -cf`
# validation before install. Installs the CLI + boot-clean service + the panel
# toggle; does NOT enable sudoless (that's a deliberate user action). The
# SudoToggleRow + its ServicesPage insert are now BAKED INTO the pinned
# hyperwebster-shell fork (Phase 2), so HYPERWEBSTER_SKIP_SHELL_PATCH tells the installer
# to skip the (now redundant) QML patch and no pacman hook is written. The CLI +
# boot-clean safety-net service still install here.
echo "==> Installing time-boxed passwordless-sudo toggle..."
arch-chroot /mnt env HYPERWEBSTER_SKIP_SHELL_PATCH=1 sh "$USER_HOME/.local/share/hyperwebster/sudo-timed-nopasswd/install-sudo-timed-nopasswd.sh" \
  || echo "    (sudo-timed-nopasswd install failed — CLI/toggle may be absent)"

# --- change 37 (cachyos-repo-switch): Settings -> Services toggle (+ CLI) to
# revert to stock Arch kernel/repos or re-enable CachyOS. Fresh installs already
# ship linux-cachyos + bootstrapped CachyOS repos (see bootstrap block above).
# Installs the CLI + visudo-validated sudoers + panel toggle. CachyRepoToggleRow
# is baked into the pinned hyperwebster-shell fork (HYPERWEBSTER_SKIP_SHELL_PATCH).
echo "==> Installing CachyOS repo + kernel switch toggle..."
arch-chroot /mnt env HYPERWEBSTER_SKIP_SHELL_PATCH=1 sh "$USER_HOME/.local/share/hyperwebster/cachyos-repo-switch/install-cachyos-repo-switch.sh" \
  || echo "    (cachyos-repo-switch install failed — CLI/toggle may be absent)"

# --- LUKS TPM2 auto-unlock helper (passphrase remains fallback).
echo "==> Installing LUKS TPM enrollment helper..."
arch-chroot /mnt sh "$USER_HOME/.local/share/hyperwebster/luks-tpm-unlock/install-luks-tpm-unlock.sh" \
  || echo "    (luks-tpm-unlock install failed)"

# --- Chimera / Deckify gaming helpers (opt-in install via hyperwebster-deckify-install).
echo "==> Installing Chimera/Deckify gaming helpers..."
arch-chroot /mnt sh "$USER_HOME/.local/share/hyperwebster/chimera-deckify-gaming/install-chimera-deckify-gaming.sh" \
  || echo "    (chimera-deckify-gaming install failed)"

# --- Tailscale: enable daemon (user runs `sudo tailscale up` to authenticate).
echo "==> Enabling Tailscale daemon..."
arch-chroot /mnt systemctl enable tailscaled.service 2>/dev/null \
  && echo "    tailscaled enabled (connect with: sudo tailscale up)" \
  || echo "    (tailscaled enable skipped — package missing?)"

# --- change 4: Flathub remote for Shelly's flatpak pages. The vendored
# .flatpakrepo embeds the GPG key, so this is an offline-safe config write.
# Staged in /root, NOT /tmp: arch-chroot mounts a fresh tmpfs over the
# target's /tmp, which shadows anything copied there from outside.
echo "==> Configuring Flathub remote..."
cp "$HYPERWEBSTER_PAYLOAD/vendor/flathub.flatpakrepo" /mnt/root/flathub.flatpakrepo
arch-chroot /mnt flatpak remote-add --if-not-exists flathub /root/flathub.flatpakrepo \
  || echo "    (flathub remote-add failed — once online run: flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo)"
rm -f /mnt/root/flathub.flatpakrepo

# --- changes 9+26: hide launcher clutter via per-user overrides. The PACKAGES
# stay (avahi-daemon is needed for .local/printer discovery, foot is a
# caelestia-meta dep, uuctl ships with uwsm) — only their menu entries
# disappear.
echo "==> Hiding launcher clutter..."
install -d -m 755 "$M_HOME/.local/share/applications"
for id in avahi-discover bssh bvnc qv4l2 qvidcap foot footclient foot-server \
          org.gnupg.pinentry-qt org.gnupg.pinentry-qt5 uuctl; do
  [ -f "/mnt/usr/share/applications/$id.desktop" ] || continue
  cat > "$M_HOME/.local/share/applications/$id.desktop" <<'HIDDEN_ENTRY'
[Desktop Entry]
Type=Application
Name=Hidden by HyperWebster
NoDisplay=true
Hidden=true
HIDDEN_ENTRY
done
# (change 9's printing piece — cups.socket — is already enabled in the base.)

# --- hardware-test 2026-06-15 (finding F-T2): stop the redundant blueman tray
# applet from autostarting. The base ships /etc/xdg/autostart/blueman.desktop,
# but blueman-applet duplicates the redesign's own bar Bluetooth pill + BlueZ
# panel (and was the only thing keeping the now-gated system-tray pill visible).
# A per-user XDG autostart override (Hidden=true) suppresses just the applet;
# the blueman package stays so blueman-manager can still be launched by hand and
# Bluetooth control is unaffected.
echo "==> Disabling redundant blueman tray applet..."
install -d -m 755 "$M_HOME/.config/autostart"
cat > "$M_HOME/.config/autostart/blueman.desktop" <<'BLUEMAN_OFF'
[Desktop Entry]
Type=Application
Name=blueman-applet
Comment=HyperWebster: redundant with the bar Bluetooth pill + BlueZ panel — disabled
Hidden=true
X-GNOME-Autostart-enabled=false
BLUEMAN_OFF
chmod 644 "$M_HOME/.config/autostart/blueman.desktop"

# --- change 24: CLIAmp default music player. The package came from pacstrap
# ([omarchy] repo); the Super+M bind is the marked block appended above. Here:
# the desktop entry (launches in kitty, class cliamp) + the audio MIME
# defaults. Nothing else writes ~/.config/mimeapps.list at install time (the
# dotfiles ship none), so a plain write is safe.
echo "==> CLIAmp default music player..."
install -m 644 "$LAYER/cliamp-music/cliamp.desktop" \
  "$M_HOME/.local/share/applications/cliamp.desktop"
{
  echo '[Default Applications]'
  for m in audio/mpeg audio/mp4 audio/x-m4a audio/aac audio/flac audio/x-flac \
           audio/ogg audio/x-vorbis+ogg audio/x-opus+ogg audio/wav audio/x-wav \
           audio/webm; do
    echo "$m=cliamp.desktop"
  done
} > "$M_HOME/.config/mimeapps.list"
chmod 644 "$M_HOME/.config/mimeapps.list"

# --- change 19: SDDM greeter themed to match the desktop. Theme dir + sync
# script + [Theme] drop-in baked from the layer tree. The shipped theme.conf
# already carries the foam-sea Material palette (matching the change-18
# default wallpaper), so the first-boot greeter matches the desktop before
# any sync has run; the background is seeded from the same wallpaper here.
# sddm-theme-sync needs a logged-in user to mirror, so it is NOT run in the
# chroot — after a wallpaper change the user runs `sudo sddm-theme-sync`.
echo "==> Installing SDDM greeter theme (caelestia)..."
install -d -m 755 /mnt/usr/share/sddm/themes/caelestia/backgrounds
install -m 644 "$LAYER/sddm-theme/caelestia/Main.qml" \
  /mnt/usr/share/sddm/themes/caelestia/Main.qml
install -m 644 "$LAYER/sddm-theme/caelestia/metadata.desktop" \
  /mnt/usr/share/sddm/themes/caelestia/metadata.desktop
install -m 644 "$LAYER/sddm-theme/caelestia/theme.conf" \
  /mnt/usr/share/sddm/themes/caelestia/theme.conf
install -m 644 "$M_HOME/Pictures/Wallpapers/hyperwebster/foam-sea.png" \
  /mnt/usr/share/sddm/themes/caelestia/backgrounds/wallpaper.png
install -m 755 "$LAYER/sddm-theme/sddm-theme-sync" /mnt/usr/local/bin/sddm-theme-sync
cat > /mnt/etc/sddm.conf.d/20-sddm-theme.conf <<'SDDMTHEME'
# Greeter theme matching the desktop scheme (sddm-theme component).
# Remove this file to fall back to SDDM's default greeter.
[Theme]
Current=caelestia
SDDMTHEME
chmod 644 /mnt/etc/sddm.conf.d/20-sddm-theme.conf

arch-chroot /mnt chown -R "$USERNAME:$USERNAME" "$USER_HOME"

# --- Per-user layer: TV profile, Raycast launcher merge, blur toggle CLI.
echo "==> Installing TV display profile + launcher polish..."
arch-chroot /mnt runuser -u "$USERNAME" -- \
  env HOME="$USER_HOME" XDG_CONFIG_HOME="$USER_HOME/.config" \
  sh "$USER_HOME/.local/share/hyperwebster/tv-gaming-display/install-tv-gaming-display.sh" \
  || echo "    (tv-gaming-display skipped)"
arch-chroot /mnt runuser -u "$USERNAME" -- \
  env HOME="$USER_HOME" XDG_CONFIG_HOME="$USER_HOME/.config" \
  sh "$USER_HOME/.local/share/hyperwebster/launcher-raycast/install-launcher-raycast.sh" \
  || echo "    (launcher-raycast skipped)"
arch-chroot /mnt runuser -u "$USERNAME" -- \
  env HOME="$USER_HOME" \
  sh "$USER_HOME/.local/share/hyperwebster/blur-toggle/install-blur-toggle.sh" \
  || echo "    (blur-toggle skipped)"

# --- hypersmooth, zephyr polish, btrfs snapshots, maintenance menu.
echo "==> Installing hypersmooth + snapshot + maintenance tools..."
arch-chroot /mnt runuser -u "$USERNAME" -- \
  env HOME="$USER_HOME" XDG_CONFIG_HOME="$USER_HOME/.config" \
  sh "$USER_HOME/.local/share/hyperwebster/hypersmooth-display/install-hypersmooth-display.sh" \
  || echo "    (hypersmooth-display skipped)"
arch-chroot /mnt runuser -u "$USERNAME" -- \
  env HOME="$USER_HOME" \
  sh "$USER_HOME/.local/share/hyperwebster/zephyr-polish/install-zephyr-polish.sh" \
  || echo "    (zephyr-polish skipped)"
arch-chroot /mnt runuser -u "$USERNAME" -- \
  env HOME="$USER_HOME" XDG_CONFIG_HOME="$USER_HOME/.config" \
  sh "$USER_HOME/.local/share/hyperwebster/distro-tools/install-distro-tools.sh" \
  || echo "    (distro-tools skipped)"
arch-chroot /mnt runuser -u "$USERNAME" -- \
  env HOME="$USER_HOME" XDG_CONFIG_HOME="$USER_HOME/.config" \
  sh "$USER_HOME/.local/share/hyperwebster/btrfs-snapshot-manager/install-btrfs-snapshot-manager.sh" \
  || echo "    (btrfs-snapshot-manager user step skipped)"
arch-chroot /mnt \
  sh "$USER_HOME/.local/share/hyperwebster/btrfs-snapshot-manager/install-btrfs-snapshot-manager.sh" \
  || echo "    (btrfs-snapshot-manager root step skipped)"

# --- LUKS TPM2 enrollment (when user opted in and TPM is present).
if [ "$USE_LUKS" -eq 0 ] && [ "${LUKS_TPM:-1}" -eq 0 ]; then
  echo "==> Enrolling LUKS volume with TPM2..."
  # Stage in /root, NOT /tmp: arch-chroot mounts a fresh tmpfs over the target /tmp.
  TPM_PW="/mnt/root/hyperwebster-luks-pw"
  echo -n "$LUKS_PW" > "$TPM_PW"
  chmod 600 "$TPM_PW"
  LUKS_DEV="/dev/disk/by-partuuid/$LUKS_PARTUUID"
  if arch-chroot /mnt hyperwebster-luks-tpm-enroll \
       --passphrase-file /root/hyperwebster-luks-pw --pcrs 7 "$LUKS_DEV"; then
    echo "    TPM2 token enrolled (passphrase remains fallback)."
    arch-chroot /mnt limine-update 2>/dev/null \
      && echo "    Limine UKI refreshed after TPM enrollment." \
      || true
  else
    echo "    TPM enrollment failed — passphrase-only unlock unchanged."
  fi
  rm -f "$TPM_PW"
fi

# --- colour scheme + wallpaper -------------------------------------------------
# The OS theme: set the default Moebius wallpaper (foam-sea.png, change 18 —
# matches the baked SDDM greeter theme), then switch the scheme to
# `dynamic` so caelestia generates the Material palette FROM the wallpaper
# (whole shell + terminals pick it up). Both CLI calls are headless-safe (PIL +
# file writes, no compositor needed; verified the same way scheme-set was).
# Order matters: `wallpaper -f` first (writes the state + thumbnail), THEN
# `scheme set -n dynamic` (regenerates colours from that thumbnail).
# Fallbacks keep the old behaviour: shadotheme scheme, no wallpaper state.
echo "==> Seeding caelestia theme (foam-sea wallpaper + dynamic scheme)..."
as_user() {
  arch-chroot /mnt runuser -u "$USERNAME" -- \
    env HOME="$USER_HOME" XDG_STATE_HOME="$USER_HOME/.local/state" \
        XDG_CONFIG_HOME="$USER_HOME/.config" XDG_CACHE_HOME="$USER_HOME/.cache" \
    "$@"
}
WALL="$USER_HOME/Pictures/Wallpapers/hyperwebster/foam-sea.png"
if as_user caelestia wallpaper -f "$WALL" >/dev/null 2>&1 \
   && as_user caelestia scheme set -n dynamic >/dev/null 2>&1 \
   && [ -f "$M_HOME/.local/state/caelestia/scheme.json" ]; then
  echo "    Dynamic scheme generated from $WALL"
else
  echo "    Dynamic scheme failed in chroot — falling back to shadotheme."
  as_user caelestia scheme set -n shadotheme >/dev/null 2>&1 || true
fi
if [ ! -f "$M_HOME/.local/state/caelestia/scheme.json" ]; then
  install -d -m 755 "$M_HOME/.local/state/caelestia"
  install -m 644 "$HYPERWEBSTER_PAYLOAD/vendor/scheme-shadotheme.json" \
    "$M_HOME/.local/state/caelestia/scheme.json"
fi
# Initial app-theme + GTK bridge (also re-runs on scheme changes via .path unit).
as_user hyperwebster-app-theme-sync >/dev/null 2>&1 || true

# --- change 25 (cont.): seed the Additions status cache so the page has data
# on first open (all 15 items not-installed on a fresh image — the page IS the
# opt-in). Needs as_user, hence here rather than next to the QML patch.
as_user "$USER_HOME/.local/bin/hyperwebster-additions" status >/dev/null 2>&1 \
  || echo "    (Additions status seed failed — run: hyperwebster-additions status)"
as_user "$USER_HOME/.local/bin/hyperwebster-update-check" >/dev/null 2>&1 \
  || echo "    (Updates status seed failed — run: hyperwebster-update-check)"

arch-chroot /mnt chown -R "$USERNAME:$USERNAME" "$USER_HOME/.local/state" 2>/dev/null || true

# --------------------------------------------------------- install cleanup ---
# The file:// repo must not leak into the installed system: drop its synced db
# (the [hyperwebster] repo is not in the target's pacman.conf) and clear the package
# cache copies pacstrap made (~3.5GB — the install media still has them all).
nsi_phase "Finishing up"
echo "==> Cleaning install-time package cache..."
rm -f /mnt/var/lib/pacman/sync/hyperwebster.*
rm -f /mnt/var/cache/pacman/pkg/*

# Heavy phase done — stop the spinner, restore on-screen output, show a centred
# completion screen.
nsi_spin_stop
trap - ERR
exec >/dev/tty 2>&1
clear
tcecho "HyperWebster install complete" "$NSI_GB" "$NSI_R"
printf '\n' >/dev/tty
tcecho "Remove the install media and reboot." "$NSI_B" "$NSI_R"
printf '\n' >/dev/tty
tcecho "First boot goes straight to the graphical login (SDDM, themed) —" "$NSI_DIM" "$NSI_R"
tcecho "log in and the themed Hyprland desktop starts. No internet needed;" "$NSI_DIM" "$NSI_R"
tcecho "run 'sudo pacman -Syu' once when you're online to sync databases." "$NSI_DIM" "$NSI_R"
printf '\n' >/dev/tty
PROMPT="Press ENTER to reboot now (Ctrl+C for a shell)... "
printf '%s' "$(nsi_pad "${#PROMPT}")" >/dev/tty
read -rp "$PROMPT" </dev/tty
# Flush ALL pending writes to disk before unmounting. With the btrfs subvolume
# layout there are 5 mounts under /mnt; `umount -R` can fail partway (it's
# tolerated below), which previously left the just-written bootloader files
# (limine.conf, BOOTX64.EFI) cached-but-unflushed on the FAT ESP — they ended up
# 0 bytes on disk and the machine wouldn't boot. An explicit sync guarantees the
# ESP writes hit the block device regardless of how the unmount goes.
sync
umount -R /mnt || true
sync
reboot
__INSTALLER_PAYLOAD__
  chmod +x "$1"
}

# ===========================================================================
# build_offline_payload — assemble ./offline/iso (mapped to /hyperwebster on the
# ISO): the complete pacman repo, vendored source tarballs, and the base
# package list. Cached: AUR builds stamp offline/aur/.built-*, downloads skip
# files already present.
# ===========================================================================
build_offline_payload() {
  echo "==> Building offline payload (cached in $OFFLINE)..."
  mkdir -p "$OFFLINE/iso/repo" "$OFFLINE/iso/vendor" "$OFFLINE/aur"
  prepare_build_mirrorlist
  write_dl_pacman_conf

  # ---- vendored source tarballs (pinned) ----------------------------------
  if [ ! -f "$OFFLINE/iso/vendor/caelestia-dotfiles.tar.gz" ]; then
    echo "==> Vendoring caelestia dotfiles ($CAELESTIA_DOTS_COMMIT)..."
    rm -rf "$OFFLINE/aur/caelestia"
    git clone "$CAELESTIA_DOTS_REPO" "$OFFLINE/aur/caelestia"
    git -C "$OFFLINE/aur/caelestia" checkout -q "$CAELESTIA_DOTS_COMMIT"
    # Tarball root dir is 'caelestia' -> extracts to ~/.local/share/caelestia.
    # .git is kept so the user can pull/diff upstream later.
    tar -czf "$OFFLINE/iso/vendor/caelestia-dotfiles.tar.gz" -C "$OFFLINE/aur" caelestia
  fi
  if [ ! -f "$OFFLINE/iso/vendor/quickshell-overview.tar.gz" ]; then
    echo "==> Vendoring quickshell-overview ($OVERVIEW_COMMIT)..."
    rm -rf "$OFFLINE/aur/overview"
    git clone "$OVERVIEW_REPO" "$OFFLINE/aur/overview"
    git -C "$OFFLINE/aur/overview" checkout -q "$OVERVIEW_COMMIT"
    # Tarball root dir is 'overview' -> extracts to ~/.config/quickshell/overview.
    tar -czf "$OFFLINE/iso/vendor/quickshell-overview.tar.gz" -C "$OFFLINE/aur" overview
  fi
  # OS theme wallpapers — repo-local user art, re-tarred EVERY build (like the
  # layer tree) so image swaps always reach the next ISO. PNGs don't compress,
  # so plain tar. Stale Last Horizon tarballs from older builds are removed.
  if [ ! -d "$WALLPAPERS_DIR" ] || [ ! -f "$WALLPAPERS_DIR/$DEFAULT_WALLPAPER" ]; then
    echo "ERROR: wallpapers not found at $WALLPAPERS_DIR (need $DEFAULT_WALLPAPER)" >&2
    exit 1
  fi
  echo "==> Vendoring OS theme wallpapers..."
  rm -f "$OFFLINE/iso/vendor/lasthorizon-wallpapers.tar.gz"
  # Tarball root dir is 'hyperwebster' -> extracts to ~/Pictures/Wallpapers/hyperwebster.
  tar -cf "$OFFLINE/iso/vendor/hyperwebster-wallpapers.tar" \
    -C "$(dirname "$WALLPAPERS_DIR")" \
    --transform 's|^wallpapers|hyperwebster|' wallpapers

  # Plymouth boot-splash theme (HyperWebster / Starman wordmark on black) — repo-local, re-tarred
  # EVERY build (like the wallpapers/layer) so logo/script edits reach the ISO.
  # Tarball root dir is 'hyperwebster' -> extracts to
  # /usr/share/plymouth/themes/hyperwebster.
  if [ ! -f "$SCRIPT_DIR/assets/plymouth/hyperwebster/hyperwebster.script" ]; then
    echo "ERROR: Plymouth theme not found at $SCRIPT_DIR/assets/plymouth/hyperwebster" >&2
    exit 1
  fi
  echo "==> Vendoring Plymouth boot-splash theme..."
  tar -czf "$OFFLINE/iso/vendor/hyperwebster-plymouth.tar.gz" \
    -C "$SCRIPT_DIR/assets/plymouth" hyperwebster
  if [ ! -f "$OFFLINE/iso/vendor/lazyvim-starter.tar.gz" ]; then
    echo "==> Vendoring LazyVim starter ($LAZYVIM_COMMIT)..."
    rm -rf "$OFFLINE/aur/lazyvim-starter"
    git clone "$LAZYVIM_REPO" "$OFFLINE/aur/lazyvim-starter"
    git -C "$OFFLINE/aur/lazyvim-starter" checkout -q "$LAZYVIM_COMMIT"
    rm -rf "$OFFLINE/aur/lazyvim-starter/.git"
    # Tarball root dir is 'nvim' -> extracts to ~/.config/nvim.
    tar -czf "$OFFLINE/iso/vendor/lazyvim-starter.tar.gz" -C "$OFFLINE/aur" \
      --transform 's|^lazyvim-starter|nvim|' lazyvim-starter
  fi
  if [ ! -f "$OFFLINE/iso/vendor/flathub.flatpakrepo" ]; then
    echo "==> Vendoring Flathub remote definition..."
    curl -fSL --proto '=https' --tlsv1.2 \
      -o "$OFFLINE/iso/vendor/flathub.flatpakrepo" "$FLATHUB_REPO_URL"
  fi
  # HyperWebster layer tree — local source, small, and actively iterated on: re-tar
  # it EVERY build (no cache stamp) so layer edits always reach the next ISO.
  if [ ! -d "$HYPERWEBSTER_LAYER_DIR" ]; then
    echo "ERROR: HyperWebster layer tree not found at $HYPERWEBSTER_LAYER_DIR" >&2
    exit 1
  fi
  echo "==> Vendoring HyperWebster layer tree..."
  # Tarball root dir is 'hyperwebster' -> extracts to ~/.local/share/hyperwebster.
  tar -czf "$OFFLINE/iso/vendor/hyperwebster-layer.tar.gz" \
    -C "$(dirname "$HYPERWEBSTER_LAYER_DIR")" \
    --transform 's|^os updates|hyperwebster|' "os updates"

  if [ ! -f "$OFFLINE/iso/vendor/omarchy-send" ]; then
    echo "==> Vendoring omarchy-send ($OMARCHY_SEND_VERSION)..."
    curl -fSL --proto '=https' --tlsv1.2 -o "$OFFLINE/iso/vendor/omarchy-send" \
      "https://github.com/$OMARCHY_SEND_REPO/releases/download/$OMARCHY_SEND_VERSION/omarchy-send-linux-amd64"
    chmod 755 "$OFFLINE/iso/vendor/omarchy-send"
  fi
  install -m 644 "$SCRIPT_DIR/assets/scheme-shadotheme.json" \
                 "$SCRIPT_DIR/assets/scheme-shadotheme-light.json" "$OFFLINE/iso/vendor/"
  install -m 644 "$SCRIPT_DIR/assets/fastfetch-config.jsonc" \
                 "$SCRIPT_DIR/assets/fastfetch-logo.txt" "$OFFLINE/iso/vendor/"

  # CachyOS repo tarball + bootstrap CLI (offline install uses these; enable/disable
  # still live-fetch when no local copy is present).
  install -m 755 "$SCRIPT_DIR/os updates/cachyos-repo-switch/hyperwebster-cachy-repo" \
    "$OFFLINE/iso/vendor/hyperwebster-cachy-repo"
  if [ ! -f "$OFFLINE/iso/vendor/cachyos-repo.tar.xz" ]; then
    echo "==> Vendoring CachyOS repo tarball (keyring/mirrorlist .awk stanzas)..."
    curl -fSL --proto '=https' --tlsv1.2 -o "$OFFLINE/iso/vendor/cachyos-repo.tar.xz" \
      "$CACHYOS_TARBALL_URL"
  fi

  # ---- bootstrap repo db (so the build chroot can reference it from day 0) -
  if [ ! -e "$OFFLINE/iso/repo/hyperwebster.db" ]; then
    tar -czf "$OFFLINE/iso/repo/hyperwebster.db.tar.gz" --files-from /dev/null
    tar -czf "$OFFLINE/iso/repo/hyperwebster.files.tar.gz" --files-from /dev/null
    ln -sf hyperwebster.db.tar.gz   "$OFFLINE/iso/repo/hyperwebster.db"
    ln -sf hyperwebster.files.tar.gz "$OFFLINE/iso/repo/hyperwebster.files"
  fi

  # ---- build chroot --------------------------------------------------------
  # Clean-room AUR builds via devtools. The chroot's pacman.conf includes the
  # local bootstrap repo: arch-nspawn auto-bind-mounts file:// Server dirs, so
  # each built package becomes resolvable by the next build (caelestia-shell
  # needs caelestia-cli + quickshell-git etc.).
  cat > "$OFFLINE/chroot-pacman.conf" <<CHROOTPAC
[options]
Architecture = auto
SigLevel = Required DatabaseOptional
LocalFileSigLevel = Optional
ParallelDownloads = 8
DisableDownloadTimeout

[hyperwebster]
SigLevel = Optional TrustAll
Server = file://$OFFLINE/iso/repo

[core]
Include = $BUILD_MIRRORLIST

[extra]
Include = $BUILD_MIRRORLIST
CHROOTPAC
  if [ ! -d "$OFFLINE/chroot/root" ]; then
    echo "==> Creating clean build chroot (devtools mkarchroot)..."
    mkdir -p "$OFFLINE/chroot"
    sudo mkarchroot -C "$OFFLINE/chroot-pacman.conf" "$OFFLINE/chroot/root" base-devel
  fi

  # ---- AUR packages (clean-chroot builds, dependency order) ----------------
  local name p
  for name in "${AUR_BUILD_ORDER[@]}"; do
    if [ -f "$OFFLINE/aur/.built-$name" ]; then
      echo "    $name: cached."
      continue
    fi
    echo "==> Building AUR package: $name..."
    rm -rf "${OFFLINE:?}/aur/$name"
    if [ "$name" = "nosignal-shell" ]; then
      # NOT an AUR package — HyperWebster's fork of the caelestia shell. Clone,
      # rebrand nosignal -> hyperwebster in QML + DISTRIBUTOR, then build from the
      # local tree (not a live git fetch) so ISO shells match hyperwebster-* CLIs.
      mkdir -p "$OFFLINE/aur/$name"
      rm -rf "$OFFLINE/aur/$name.fork"
      git clone --depth 1 "$HYPERWEBSTER_SHELL_REPO" -b nosignal "$OFFLINE/aur/$name.fork"
      ( cd "$OFFLINE/aur/$name.fork" && git fetch --depth 1 origin "$HYPERWEBSTER_SHELL_COMMIT" && git checkout -q "$HYPERWEBSTER_SHELL_COMMIT" )
      SHELL_ROOT="$OFFLINE/aur/$name.fork" sh "$HYPERWEBSTER_LAYER_DIR/shell-branding/patch-shell-branding.sh"
      rm -rf "$OFFLINE/aur/$name/nosignal-shell"
      cp -a "$OFFLINE/aur/$name.fork" "$OFFLINE/aur/$name/nosignal-shell"
      cp "$OFFLINE/aur/$name.fork/packaging/PKGBUILD" "$OFFLINE/aur/$name/PKGBUILD"
      sed -i 's|^source=.*|source=("nosignal-shell")|' "$OFFLINE/aur/$name/PKGBUILD"
      sed -i 's|DDISTRIBUTOR="NoSignal (package: $_pkgname)"|DDISTRIBUTOR="HyperWebster (package: $_pkgname)"|' \
        "$OFFLINE/aur/$name/PKGBUILD"
      sed -i 's|pkgdesc="NoSignal desktop shell|pkgdesc="HyperWebster desktop shell|' \
        "$OFFLINE/aur/$name/PKGBUILD"
    else
      git clone --depth 1 "https://aur.archlinux.org/$name.git" "$OFFLINE/aur/$name"
    fi
    if [ "$name" = "quickshell-git" ]; then
      # Pin to the validated commit (makepkg git source fragment).
      sed -i 's|git+\$url\.git|&#commit='"$QUICKSHELL_GIT_COMMIT"'|' "$OFFLINE/aur/$name/PKGBUILD"
    fi
    # Self-heal the clean chroot's [hyperwebster] repo path: a project rename
    # (hyprOS -> hyperwebster) leaves a stale Server path baked into the chroot's
    # persistent pacman.conf, which only bites the first chroot build after the
    # move (cached AUR pkgs skip the build). Keep it pointed at the live OFFLINE.
    for pc in "$OFFLINE"/chroot/*/etc/pacman.conf; do
      [ -f "$pc" ] && sudo sed -i "s#file:///.*/offline/iso/repo#file://$OFFLINE/iso/repo#g" "$pc"
    done
    # Refresh the ROOT chroot's sync dbs first: makechrootpkg -c clones the
    # copy from root, and the dependency install inside runs withOUT -Sy — so
    # without this, packages repo-added to [hyperwebster] after mkarchroot are
    # invisible and chained builds fail with "target not found".
    sudo arch-nspawn "$OFFLINE/chroot/root" pacman -Syu --noconfirm
    ( cd "$OFFLINE/aur/$name" && sudo makechrootpkg -c -r "$OFFLINE/chroot" )
    for p in "$OFFLINE/aur/$name"/*.pkg.tar.zst; do
      [[ "$(basename "$p")" == *-debug-* ]] && continue
      cp -f "$p" "$OFFLINE/iso/repo/"
      repo-add -R "$OFFLINE/iso/repo/hyperwebster.db.tar.gz" "$OFFLINE/iso/repo/$(basename "$p")"
    done
    touch "$OFFLINE/aur/.built-$name"
  done

  # caelestia-meta builds from the PKGBUILD inside the dotfiles repo itself
  # (the AUR snapshot lags it — the dotfiles clone is the authoritative
  # source). Pure metapackage: no build() step, so plain makepkg -d on the
  # host is safe (no dep pollution; pkgver() just needs git).
  # PRIVACY: host makepkg records builddir/startdir in the package's
  # .BUILDINFO — built from $HOME that would ship the builder's username on a
  # distributable ISO. Build from a neutral /tmp copy instead. (Chroot-built
  # packages don't have this problem: their paths are /build.)
  if [ ! -f "$OFFLINE/aur/.built-caelestia-meta" ]; then
    echo "==> Building caelestia-meta (from the pinned dotfiles clone)..."
    if [ ! -d "$OFFLINE/aur/caelestia/.git" ]; then
      rm -rf "$OFFLINE/aur/caelestia"
      git clone "$CAELESTIA_DOTS_REPO" "$OFFLINE/aur/caelestia"
      git -C "$OFFLINE/aur/caelestia" checkout -q "$CAELESTIA_DOTS_COMMIT"
    fi
    meta_tmp=$(mktemp -d /tmp/hyperwebster-meta.XXXXXX)
    cp -a "$OFFLINE/aur/caelestia" "$meta_tmp/caelestia"   # keep .git (pkgver)
    ( cd "$meta_tmp/caelestia" && rm -f ./*.pkg.tar.zst \
        && BUILDDIR="$meta_tmp/build" makepkg -df --noconfirm )
    for p in "$meta_tmp/caelestia"/*.pkg.tar.zst; do
      cp -f "$p" "$OFFLINE/iso/repo/"
      repo-add -R "$OFFLINE/iso/repo/hyperwebster.db.tar.gz" "$OFFLINE/iso/repo/$(basename "$p")"
    done
    rm -rf "$meta_tmp"
    touch "$OFFLINE/aur/.built-caelestia-meta"
  fi

  # ---- full repo dependency closure ----------------------------------------
  # Resolve EVERYTHING the installer can possibly pacstrap — base set, every
  # GPU variant, the limine tools (prebuilt, from the omarchy repo) and the
  # caelestia stack (from the local repo, pulling its repo deps) — against an
  # EMPTY local db, and download into the repo dir. Already-present files are
  # skipped, so this is cheap on rebuilds.
  download_offline_closure

  # ---- finalise the repo ----------------------------------------------------
  # Prune superseded package versions, then rebuild the db from everything
  # present so it exactly matches the files shipped on the ISO.
  if command -v paccache >/dev/null 2>&1; then
    paccache -rqk1 -c "$OFFLINE/iso/repo" || true
  else
    echo "    (paccache not found — old package versions may bloat the ISO;"
    echo "     install pacman-contrib to enable pruning)"
  fi

  # F5 (2026-06-12 hardware test): hyprland 0.55.3 segfaults at screen lock
  # (renderer SEGV during lock/DPMS monitor churn; the watchdog then drops to
  # the confusing safe-mode "basic desktop"). 0.55.4 backports the #15048 fix
  # and was retested clean on the test box — refuse to ship anything older.
  local hyprver
  hyprver=$(basename "$(ls "$OFFLINE/iso/repo"/hyprland-[0-9]*.pkg.tar.zst | sort -V | tail -1)")
  hyprver=${hyprver#hyprland-}; hyprver=${hyprver%-x86_64.pkg.tar.zst}
  if [ "$(vercmp "$hyprver" 0.55.4)" -lt 0 ]; then
    echo "ERROR: offline repo has hyprland $hyprver — F5 requires >= 0.55.4" >&2
    echo "       (lock-screen renderer SEGV). Refresh mirrors and rebuild." >&2
    exit 1
  fi
  echo "    hyprland $hyprver (>= 0.55.4, F5 lock-screen fix) OK"

  echo "==> Building repo database..."
  # Drop detached signatures (omarchy ships them): repo-add would embed them
  # in the db and pacman then REQUIRES the signing key even under TrustAll.
  # Offline install verifies nothing (SigLevel Never) — the sigs are dead weight.
  rm -f "$OFFLINE/iso/repo"/*.sig
  rm -f "$OFFLINE/iso/repo"/hyperwebster.db* "$OFFLINE/iso/repo"/hyperwebster.files* "$OFFLINE/iso/repo"/*.old
  repo-add -q "$OFFLINE/iso/repo/hyperwebster.db.tar.gz" "$OFFLINE/iso/repo"/*.pkg.tar.zst
  # ISO9660-safe: ship the .db/.files as REAL files, not symlinks.
  local f
  for f in db files; do
    rm -f "$OFFLINE/iso/repo/hyperwebster.$f"
    cp "$OFFLINE/iso/repo/hyperwebster.$f.tar.gz" "$OFFLINE/iso/repo/hyperwebster.$f"
  done

  # ---- base package list (single source of truth for the installer) --------
  printf '%s\n' "${BASE_PKGS[@]}" > "$OFFLINE/iso/base-packages.list"

  echo "==> Offline payload ready: $(du -sh "$OFFLINE/iso" | cut -f1)"
}

# ===========================================================================
# Host-side workflow: locate stock ISO, build offline payload, unsquash,
# inject, re-squash, repack, output.
# ===========================================================================

# ---- locate stock ISO ----------------------------------------------------
shopt -s nullglob
CANDIDATES=("$SCRIPT_DIR"/archlinux-*.iso)
shopt -u nullglob
STOCK_ISO=""
for iso in "${CANDIDATES[@]}"; do
  [[ "$(basename "$iso")" == *HyperWebster* ]] && continue
  STOCK_ISO="$iso"
  break
done

if [ -z "$STOCK_ISO" ]; then
  echo "ERROR: No stock Arch ISO found in $SCRIPT_DIR" >&2
  echo >&2
  echo "Download the latest from https://archlinux.org/download/ and put it" >&2
  echo "in this folder (filename must start with 'archlinux-')." >&2
  exit 1
fi

echo "  Stock ISO: $(basename "$STOCK_ISO")"
echo "  Output:    $(basename "$OUT_ISO")"
echo

# ---- tooling check -------------------------------------------------------
for cmd in xorriso unsquashfs mksquashfs git sha512sum mkarchroot makechrootpkg repo-add makepkg; do
  command -v "$cmd" >/dev/null || {
    echo "ERROR: missing tool: $cmd" >&2
    echo "       install with: sudo pacman -S libisoburn squashfs-tools git coreutils devtools pacman-contrib" >&2
    exit 1
  }
done

# ---- OPTIONAL master SSH public key (OPT-IN ONLY) -------------------------
# The ISO is distributable: by default NO key is baked and sshd stays disabled
# on installed systems — nothing identifying the build host ships on the
# image. For a personal/dev build (remote rescue over SSH), opt in explicitly:
#   SSH_PUBKEY=/path/to/key.pub ./hyperwebster.sh
# (The old behaviour of auto-baking ~/.ssh/id_*.pub was removed deliberately —
#  do not reintroduce it; a give-away ISO must never carry the builder's key.)
SSH_PUBKEY="${SSH_PUBKEY:-}"
HAVE_KEY=0
if [ -z "$SSH_PUBKEY" ] || [ "$SSH_PUBKEY" = "none" ]; then
  echo "  SSH key:   (none — sshd disabled on installs; distributable default."
  echo "              Opt in with SSH_PUBKEY=/path/to/key.pub for a dev build.)"
elif [ -f "$SSH_PUBKEY" ]; then
  HAVE_KEY=1
  echo "  SSH key:   $SSH_PUBKEY (DEV BUILD — key baked in, sshd enabled on installs;"
  echo "              do NOT distribute this ISO)"
else
  echo "ERROR: SSH_PUBKEY=$SSH_PUBKEY not found" >&2
  exit 1
fi

# ---- offline payload ------------------------------------------------------
build_offline_payload

# ---- workspace -----------------------------------------------------------
sudo rm -rf "$WORK"
mkdir -p "$WORK"
SFS_DIR="$WORK/airootfs"

# ---- pull squashfs out of the stock ISO ---------------------------------
echo "==> Extracting airootfs.sfs from stock ISO..."
xorriso -osirrox on -indev "$STOCK_ISO" \
  -extract /arch/x86_64/airootfs.sfs "$WORK/airootfs-stock.sfs" 2>&1 | tail -3

echo "==> Unsquashing airootfs (slow: ~1 min)..."
sudo unsquashfs -d "$SFS_DIR" "$WORK/airootfs-stock.sfs" >/dev/null

# ---- inject payload ------------------------------------------------------
if [ "$HAVE_KEY" = 1 ]; then
  echo "==> Staging master SSH key for first-boot SSH access..."
  sudo install -m 644 -o root -g root "$SSH_PUBKEY" "$SFS_DIR/root/master.pub"
fi

echo "==> Injecting installer.sh..."
INSTALLER_TMP="$WORK/installer.sh"
write_installer "$INSTALLER_TMP"
sudo install -m 755 -o root -g root "$INSTALLER_TMP" "$SFS_DIR/root/installer.sh"

echo "==> Masking online-only units (they hang/hijack the console offline)..."
# With no network, archlinux-keyring-wkd-sync pulls systemd-time-wait-sync,
# which waits for NTP sync FOREVER ("no limit") and repaints the console with
# its start-job spinner right over the running installer. Useless offline.
for unit in systemd-time-wait-sync.service archlinux-keyring-wkd-sync.service archlinux-keyring-wkd-sync.timer; do
  sudo ln -sf /dev/null "$SFS_DIR/etc/systemd/system/$unit"
done

echo "==> Wiring getty@tty1 to auto-launch the installer..."
sudo mkdir -p "$SFS_DIR/etc/systemd/system/getty@tty1.service.d"
sudo tee "$SFS_DIR/etc/systemd/system/getty@tty1.service.d/override.conf" >/dev/null <<'EOF'
[Service]
ExecStart=
ExecStart=-/usr/bin/bash /root/installer.sh
StandardInput=tty
StandardOutput=tty
Restart=no
RestartPreventExitStatus=1 2 3 4 5 6 7 8
EOF

# ---- extend USB enumeration timeout in boot loader cmdline --------------
# Slow / fussy USB controllers (some Intel mini-PCs, NUCs) don't enumerate USB
# block devices within archiso's default search window. Adding rootdelay=60 to
# the kernel cmdline makes initramfs wait 60s before mounting root — fast
# hardware finds the device in 2s and moves on; slow hardware gets breathing
# room. consoleblank=0 keeps the live install console from DPMS-blanking.
echo "==> Patching bootloader cmdlines (rootdelay=60 for slow USB enumeration)..."
mkdir -p "$WORK/boot-edit"
BOOT_CFG_FILES=(
  /loader/entries/01-archiso-linux.conf
  /loader/entries/02-archiso-speech-linux.conf
  /boot/syslinux/archiso_sys-linux.cfg
)
for path in "${BOOT_CFG_FILES[@]}"; do
  dest="$WORK/boot-edit/$(basename "$path")"
  # Don't pipe xorriso straight into tail — that masks its exit status under
  # 'set -e', so a missing boot file would slip through here and instead blow
  # up later at the unconditional -map during repack, with a murkier error.
  if ! xorriso -osirrox on -indev "$STOCK_ISO" -extract "$path" "$dest" 2>"$WORK/xorriso-extract.log"; then
    echo "ERROR: failed to extract $path from stock ISO:" >&2
    tail -3 "$WORK/xorriso-extract.log" >&2
    exit 1
  fi
done
for f in "$WORK/boot-edit"/*; do
  [ -f "$f" ] || continue
  sed -i -E '/archisosearchuuid=/ { /rootdelay=/!     s/$/ rootdelay=60/     }' "$f"
  sed -i -E '/archisosearchuuid=/ { /consoleblank=/!  s/$/ consoleblank=0/   }' "$f"
done

# ---- re-squash -----------------------------------------------------------
echo "==> Re-squashing airootfs (slow: ~2 min)..."
sudo rm -f "$WORK/airootfs.sfs"
sudo mksquashfs "$SFS_DIR" "$WORK/airootfs.sfs" \
  -comp xz -Xbcj x86 -b 1M -noappend -no-progress -quiet

# ---- regenerate sha512 --------------------------------------------------
echo "==> Recalculating airootfs.sha512..."
( cd "$WORK" && sudo sha512sum airootfs.sfs | sudo tee airootfs.sha512 >/dev/null )

# ---- repack ISO ---------------------------------------------------------
# -boot_image any replay regenerates the hybrid MBR/GPT + El Torito layout
# SIZED TO THE NEW IMAGE. Never copy the stock system_area verbatim: its
# partition table describes the stock 1.2GB ISO, so everything past that
# (the /hyperwebster payload) lands OUTSIDE any partition and is unreadable when
# the media is mounted via a partition device (USB boot on real hardware).
echo "==> Repacking ISO (offline repo + replayed boot layout + volume UUID)..."
sudo rm -f "$OUT_ISO"

# Force output volume UUID to match the stock's. archiso's initramfs hook
# searches for the boot media by this UUID (also baked into the kernel cmdline
# as archisosearchuuid=) — if xorriso regenerates the UUID with a fresh build
# timestamp, the search misses the USB entirely. Pinning the UUID keeps stock
# cmdline + marker file in sync.
STOCK_UUID=$(blkid -s UUID -o value "$STOCK_ISO")
STOCK_UUID_RAW=$(echo "$STOCK_UUID" | tr -d '-')

xorriso \
  -indev "$STOCK_ISO" \
  -outdev "$OUT_ISO" \
  -volume_date "uuid" "$STOCK_UUID_RAW" \
  -boot_image any replay \
  -rm /arch/x86_64/airootfs.sfs -- \
  -map "$WORK/airootfs.sfs" /arch/x86_64/airootfs.sfs \
  -rm /arch/x86_64/airootfs.sha512 -- \
  -map "$WORK/airootfs.sha512" /arch/x86_64/airootfs.sha512 \
  -rm /loader/entries/01-archiso-linux.conf -- \
  -map "$WORK/boot-edit/01-archiso-linux.conf" /loader/entries/01-archiso-linux.conf \
  -rm /loader/entries/02-archiso-speech-linux.conf -- \
  -map "$WORK/boot-edit/02-archiso-speech-linux.conf" /loader/entries/02-archiso-speech-linux.conf \
  -rm /boot/syslinux/archiso_sys-linux.cfg -- \
  -map "$WORK/boot-edit/archiso_sys-linux.cfg" /boot/syslinux/archiso_sys-linux.cfg \
  -map "$OFFLINE/iso" /hyperwebster \
  -end 2>&1 | tail -5

# ---- cleanup ------------------------------------------------------------
sudo chown "$INVOKING_USER:$INVOKING_GROUP" "$OUT_ISO"
sudo rm -rf "$WORK"

echo
echo "=========================================================="
echo "  Done: $OUT_ISO"
echo "  Size: $(du -h "$OUT_ISO" | cut -f1)"
echo
echo "  Fully offline installer — no network needed on the target."
echo
echo "  Burn to USB:"
echo "    sudo dd if='$OUT_ISO' of=/dev/sdX bs=4M status=progress conv=fsync"
echo
echo "  Or drop $(basename "$OUT_ISO") into your Ventoy USB."
echo "=========================================================="
