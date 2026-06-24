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
- **Btrfs + bootable snapshots** via snapper/snap-pac; roll back from Limine.
- **`hyperwebster-update`** - snapshot → upgrade → layer migrations.
- **Gaming (opt-in)**: Deckify/Chimera (`hyperwebster-deckify-install`) or DeckShift;
  `Super+Shift+S` or Limine Starman for Steam Big Picture.

## Build the ISO

On an **Arch Linux** host with internet:

```bash
sudo pacman -S --needed git libisoburn squashfs-tools coreutils devtools pacman-contrib
git clone https://github.com/spundone/HyperWebster-OS.git
cd HyperWebster-OS
curl -LO https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso
./hyperwebster.sh
```

Output: `hyperwebster-arch-YYYYMMDD.iso` (~4 GB). Cached payload in `./offline/`.

The offline repo includes `linux-cachyos`, `cachyos-kernel-manager`, `tailscale`,
and CachyOS trust packages (downloaded from [CachyOS mirrors](https://mirror.cachyos.org)
at build time). Delete `./offline/` to force a full refresh after upstream bumps.

## Install

1. Write the ISO to USB (`dd` or Ventoy). **UEFI only.**
2. Boot and follow the offline installer: hostname, user, password, region,
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

## Credits

See [docs/CREDITS.md](docs/CREDITS.md) for the full list. Key upstream projects:
NoSignal OS, Arch Linux, Hyprland, caelestia, Quickshell, SDDM, Limine, Omarchy,
ChimeraOS, Deckify, DeckShift, CachyOS, Tailscale.

## License

MIT - see [LICENSE](LICENSE).
