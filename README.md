# HyperWebster OS

An Arch Linux desktop ISO builder - forked from
[NoSignal OS](https://github.com/28allday/NoSignal-OS) and continuing the
**hyperarch** lineage as **HyperWebster · Starman OS**. Tuned for gaming desktops
and living-room TV setups (4K HDR, VRR, AMD or NVIDIA GPUs). One script turns a
stock Arch ISO into a fully offline Hyprland + caelestia installer.

See [docs/HARDWARE.md](docs/HARDWARE.md) for hardware guidance and
[docs/CREDITS.md](docs/CREDITS.md) for full upstream attribution.

> HyperWebster is the *ISO builder*. It bundles and installs the upstream caelestia
> dotfiles; it is not affiliated with that project.

## Disclaimer

> **Vibecoded and experimental.** This repository was built largely with AI-assisted
> development. It has **not been tested** on real hardware at scale and is meant for
> **personal use only for now**. Use at your own risk - there is no warranty, and the
> ISO builder should be treated as experimental.

## What you get on the installed system

- **Hyprland + caelestia shell** (Quickshell), restyled with a restrained flat
  look by default; optional frosted glass via `hyperwebster-blur-toggle enable`.
- **LUKS2 disk encryption** with optional **TPM2 auto-unlock** at install
  (passphrase sealed in TPM; remains fallback). Plymouth may show briefly before SDDM.
- **Themed SDDM login** that mirrors the desktop palette; auto-syncs when you
  switch light/dark mode.
- **Limine boot menu** with UKI snapshots **plus a Starman (Gaming / Steam)**
  entry - boots into gamescope Steam when Deckify/Chimera or DeckShift is installed.
- **CachyOS `linux-cachyos` kernel** + **`cachyos-kernel-manager`** - default OOB;
  CachyOS pacman repos bootstrapped at install; stock `linux` kept as Limine fallback.
- **4K HDR TV profile** - `hyprmoncfg apply tv-gaming-4k` for 4K144 HDR VRR.
- **Tailscale** preinstalled (`sudo tailscale up` to connect).
- **Raycast-like launcher** - fuzzy search on Super+Space.
- **Data drive automount** - non-system disks premount under `/mnt/<label>` at boot.
- **Omarchy-style keybindings** - `Super+K` cheatsheet, `Super+Space` launcher,
  `Super+D` dashboard, `Super+Grave` workspace overview.
- **Omarchy-inspired utilities** - `omarchy-send` LAN sharing (`Super+Ctrl+S`),
  media transcode (`Super+Ctrl+Period`), OCR capture (`Super+Ctrl+Print`),
  night light toggle (`Super+Ctrl+N`), Omarchy bash setup + `[omarchy]` repo.
- **Software story**: `yay` (AUR), **Shelly** on `Super+I`, flatpak preconfigured.
- **Btrfs + bootable snapshots** via snapper/snap-pac; **btrfs-assistant** GUI +
  timeline snapshots; roll back from Limine.
- **120/144 Hz hypersmooth UI** - VFR + tuned Hyprland/shell animation durations OOB.
- **Optional zephyr motion** - `hyperwebster-zephyr-polish enable` for overshoot flair.
- **Maintenance menu** - `Super+Ctrl+Shift+M` (`hyperwebster-maint`).
- **`hyperwebster-update`** - snapshot → upgrade → layer migrations.
- **Gaming (opt-in)**: Deckify/Chimera (`hyperwebster-deckify-install`) or DeckShift;
  `Super+Shift+S` or Limine Starman for Steam Big Picture.

## Build the ISO

On an **Arch Linux** host with internet:

```bash
sudo pacman -S --needed git libisoburn squashfs-tools coreutils devtools pacman-contrib reflector util-linux
git clone https://github.com/spundone/HyperWebster-OS.git
cd HyperWebster-OS
./hyperwebster.sh
```

If no stock Arch ISO (`archlinux-*.iso`) is in the repo root, the script **downloads
the latest automatically** from official mirrors (~1.3 GB). To supply your own ISO
instead, place it in the repo root or set `HYPERWEBSTER_ARCH_ISO`. Set
`HYPERWEBSTER_SKIP_ISO_DOWNLOAD=1` to restore fail-fast behavior when the ISO is
missing.

Output: `hyperwebster-arch-YYYYMMDD.iso` (~4 GB). Cached payload in `./offline/`.

**Cross-platform entry point:** `./build.sh` detects your host and either runs
`hyperwebster.sh` natively (Arch) or inside an Arch container (macOS, Ubuntu, etc.).

### Building on macOS / non-Arch Linux

The ISO builder needs Arch tooling (`pacman`, `devtools`/`mkarchroot`, `xorriso`,
squashfs). Native macOS builds are not supported; use **Docker Desktop** (or Podman)
to run an Arch container with the repo bind-mounted.

**Requirements**

- Docker Desktop for Mac (or Podman on Linux) with ~30 GB free disk
- Stable internet for the first build (stock ISO auto-download + AUR + packages)

**Step by step (macOS)**

1. Install [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/).
2. Clone the repo (stock Arch ISO is downloaded on first build if missing):

   ```bash
   git clone https://github.com/spundone/HyperWebster-OS.git
   cd HyperWebster-OS
   git checkout feature/cross-platform-build   # until merged to main
   ```

3. Run the wrapper (builds the Arch image on first run, then builds the ISO):

   ```bash
   chmod +x build.sh scripts/build-in-container.sh
   ./build.sh
   ```

4. Output appears in the repo root: `hyperwebster-arch-YYYYMMDD.iso`.
   Subsequent builds reuse `offline/` (delete it to force a full refresh).

**Alternatives**

- **VS Code / Cursor devcontainer:** open the repo and “Reopen in Container”
  (`.devcontainer/devcontainer.json`), then run `./hyperwebster.sh` in the
  integrated terminal.
- **Arch VM (UTM, QEMU, libvirt):** clone the repo into a shared folder on an
  Arch guest and run `./hyperwebster.sh` natively — same as bare-metal Arch.
- **Force container on Arch:** `HYPERWEBSTER_FORCE_CONTAINER=1 ./build.sh`

**Useful env vars** (native or container): `HYPERWEBSTER_ARCH_ISO`,
`HYPERWEBSTER_ARCH_ISO_URL`, `HYPERWEBSTER_SKIP_ISO_DOWNLOAD=1`,
`HYPERWEBSTER_MIRRORLIST`, `HYPERWEBSTER_REFRESH_MIRRORS=1`, `SSH_PUBKEY`
(dev builds only). See `hyperwebster.sh` header comments.

The offline repo includes `linux-cachyos`, `cachyos-kernel-manager`, `tailscale`,
and CachyOS trust packages (downloaded from [CachyOS mirrors](https://mirror.cachyos.org)
at build time). Delete `./offline/` to force a full refresh after upstream bumps.

## Install

1. Write the ISO to USB (`dd` or Ventoy). **UEFI only.**
2. Boot and follow the offline installer: hostname (default `hyperarch`), user, password, region,
   **LUKS encryption** (recommended), **TPM2 auto-unlock** (when TPM present),
   target disk.
3. Layout: 1 GiB EFI + LUKS/btrfs with `@`/`@home`/`@snapshots`/`@log` + Limine.
4. Reboot into SDDM. Run `sudo pacman -Syu` once online (syncs CachyOS + Arch dbs).
   Optional: Settings → Services → **CachyOS kernel & repos** → ON to convert
   userspace packages to CachyOS optimized builds (reboot after).
5. Settings → Additions → **Deckify / Chimera Gaming** (or DeckShift) for Starman boot.
6. `sudo tailscale up` for remote access.

## GPU detection

| Detected | Packages |
|----------|----------|
| AMD (`1002`) | `mesa vulkan-radeon` |
| NVIDIA (`10de`) | `nvidia-open-dkms` stack + Wayland KMS |
| Intel (`8086`) | `mesa vulkan-intel intel-media-driver` |

The installer scans PCI vendor IDs and installs the matching driver stack automatically.

## Customising the desktop

HyperWebster tweaks live in a **config-override layer** at `~/.config/caelestia/`
and `~/.local/share/hyperwebster/`. Delete a file to revert one change.
`hyperwebster-update` snapshots before every upgrade.

```sh
hyperwebster-blur-toggle enable      # frosted glass (optional)
hyperwebster-zephyr-polish enable    # optional zephyr overshoot motion
hyperwebster-maint                   # maintenance menu (or Super+Ctrl+Shift+M)
hyperwebster-snapshots               # btrfs / snapper shortcuts
hyperwebster-launcher-raycast        # refresh Raycast-like launcher settings
hyprmoncfg apply tv-gaming-4k        # 4K HDR TV display profile
hyperwebster-transcode               # resize media for sharing (Omarchy-style)
omarchy-send                         # LAN file transfer TUI
```

## Omarchy-inspired features

HyperWebster cherry-picks Omarchy's UX without shipping the full distro.
See `os updates/omarchy-extras/README.md` for the full mapping.

| Feature | Key / command | Notes |
|---------|---------------|-------|
| Keybinding layout | `Super+K` cheatsheet | Full Omarchy default map on caelestia |
| LAN file share | `Super+Ctrl+S`, `omarchy-send` | [28allday/omarchy-send](https://github.com/28allday/omarchy-send) |
| Media transcode | `Super+Ctrl+Period` | fuzzel menus; `omarchy-transcode` shim for bash aliases |
| OCR capture | `Super+Ctrl+Print` | grim + tesseract |
| Night light | `Super+Ctrl+N` | hyprsunset; Quick Settings tile too |
| Bash shell setup | default login shell | Vendored from Omarchy `default/bash` |
| Developer polish | omadots configs | starship, tmux, btop, LazyVim |
| Gaming installer shims | `omarchy-pkg-add` etc. | DeckShift / Chimera compatibility |
| Limine snapshot tools | `[omarchy]` pacman repo | Prebuilt `limine-snapper-sync` updates |

**Not ported:** Walker/Elephant launcher (caelestia launcher instead), Waybar,
theme/background switchers, Omarchy reminders, full `omarchy` CLI menus.


On-box AI guide: `~/.claude/skills/hyperwebster/SKILL.md` and
`~/.local/share/hyperwebster/ONBOX-AI-NOTES.md`.

## Hardware testing notes

Features worth validating on your hardware:

| Feature | What to verify |
|---------|----------------|
| TPM2 LUKS unlock | Cold boot without passphrase; fallback after BIOS change |
| 4K HDR / VRR TV | `hyprctl monitors`; gamescope session on your display |
| Starman boot | Limine entry → gamescope Steam without SDDM password |

## Notes

- **UEFI only.** No BIOS/MBR.
- **LUKS2** encrypts the root partition; back up your passphrase even with TPM enrolled.
- NVIDIA open modules target Turing+ (RTX 20-series and newer).
- Package snapshot is from build day - run `sudo pacman -Syu` once online.

## Troubleshooting (ISO build)

### Pacman mirror timeouts during `./hyperwebster.sh`

The offline-repo download phase pulls hundreds of packages from Arch mirrors on
the **build host**. A single slow mirror (for example `geo.mirror.pkgbuild.com`
stalling below 1 byte/sec) makes pacman abort with "too many errors from a
single mirror".

**What the script does now:** it ranks mirrors with `reflector` when available,
falls back to a curated multi-mirror list, sets `DisableDownloadTimeout` and
`ParallelDownloads`, and retries failed downloads up to three times (refreshing
mirrors between attempts).

**Retry the build:**

```bash
# Force fresh mirror ranking, then rebuild (reuses cached AUR builds)
HYPERWEBSTER_REFRESH_MIRRORS=1 ./hyperwebster.sh
```

**Optional — rank mirrors yourself first:**

```bash
sudo reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
HYPERWEBSTER_MIRRORLIST=/etc/pacman.d/mirrorlist ./hyperwebster.sh
```

**Still failing?** Delete only the partial download cache and retry (keeps AUR
build stamps in `offline/aur/`):

```bash
rm -f offline/build-mirrorlist offline/dl-pacman.conf
rm -rf offline/dl-db
HYPERWEBSTER_REFRESH_MIRRORS=1 ./hyperwebster.sh
```

For a full package refresh (slow), delete the entire `offline/` directory.

## Credits

See [docs/CREDITS.md](docs/CREDITS.md) for the full list. Key upstream projects:
NoSignal OS, Arch Linux, Hyprland, caelestia, Quickshell, SDDM, Limine, Omarchy,
ChimeraOS, Deckify, DeckShift, CachyOS, zephyr, Tailscale.

## License

MIT - see [LICENSE](LICENSE).
