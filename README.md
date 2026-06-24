# HyperWebster OS

A **personal** Arch Linux desktop ISO builder — forked from
[NoSignal OS](https://github.com/28allday/NoSignal-OS) and continuing the
**hyperarch** lineage as **HyperWebster · Starman OS**. Tuned for a dedicated
gaming workstation (AMD Ryzen 7 5700X3D + Radeon RX 9070); one script turns a
stock Arch ISO into a fully offline Hyprland + caelestia installer.

See [docs/HARDWARE.md](docs/HARDWARE.md) for the target machine profile and
[docs/CREDITS.md](docs/CREDITS.md) for full upstream attribution.

> HyperWebster is the *ISO builder*. It bundles and installs the upstream caelestia
> dotfiles; it is not affiliated with that project.

## What you get on the installed system

- **Hyprland + caelestia shell** (Quickshell), restyled with a restrained flat
  look (no blur/glassmorphism) and a Moebius-style wallpaper set (dynamic Material
  palette from the wallpaper).
- **LUKS2 disk encryption** on the root partition (optional at install; EFI stays
  plain). Plymouth prompts for the passphrase on cold boot.
- **Themed SDDM login** that mirrors the desktop palette; auto-syncs when you
  switch light/dark mode.
- **Limine boot menu** with UKI snapshots **plus a Starman (Gaming / Steam)**
  entry — boots straight into the gamescope Steam session when DeckShift is installed.
- **Data drive automount** — non-system disks premount under `/mnt/<label>` at
  boot (`nofail`).
- **Omarchy-style keybindings** — `Super+K` cheatsheet, `Super+Space` launcher,
  `Super+D` dashboard, `Super+Grave` workspace overview.
- **Software story**: `yay` (AUR), **Shelly** on `Super+I`, flatpak preconfigured.
- **Btrfs + bootable snapshots** via snapper/snap-pac; roll back from Limine.
- **`hyperwebster-update`** — snapshot → upgrade → layer migrations.
- **Gaming (opt-in)**: `[multilib]` + DeckShift shims; `Super+Shift+S` or the
  Limine Starman entry for Steam Big Picture.
- Light/dark mode bridged to GTK apps, icons, and the login greeter.

## Build the ISO

On an **Arch Linux** host with internet:

```bash
sudo pacman -S --needed git libisoburn squashfs-tools coreutils devtools pacman-contrib
git clone <your-remote-url> HyperWebster-OS
cd HyperWebster-OS
curl -LO https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso
./hyperwebster.sh
```

Output: `hyperwebster-arch-YYYYMMDD.iso` (~4 GB). Cached payload in `./offline/`.

## Install

1. Write the ISO to USB (`dd` or Ventoy). **UEFI only.**
2. Boot and follow the offline installer: hostname, user, password, region,
   **LUKS encryption** (recommended), target disk.
3. Layout: 1 GiB EFI + LUKS/btrfs with `@`/`@home`/`@snapshots`/`@log` + Limine.
4. Reboot into SDDM. Run `sudo pacman -Syu` once online.

## GPU detection

| Detected | Packages |
|----------|----------|
| AMD (`1002`) | `mesa vulkan-radeon` |
| NVIDIA (`10de`) | `nvidia-open-dkms` stack + Wayland KMS |
| Intel (`8086`) | `mesa vulkan-intel intel-media-driver` |

The primary gaming box uses **AMD RX 9070** — installer selects the AMD row.

## Customising the desktop

HyperWebster tweaks live in a **config-override layer** at `~/.config/caelestia/`
and `~/.local/share/hyperwebster/`. Delete a file to revert one change.
`hyperwebster-update` snapshots before every upgrade.

On-box AI guide: `~/.claude/skills/hyperwebster/SKILL.md` and
`~/.local/share/hyperwebster/ONBOX-AI-NOTES.md`.

## Notes

- **UEFI only.** No BIOS/MBR.
- **LUKS2** encrypts the root partition; back up your passphrase.
- NVIDIA open modules target Turing+ (RTX 20-series and newer).
- Package snapshot is from build day — run `sudo pacman -Syu` once online.

## Credits

See [docs/CREDITS.md](docs/CREDITS.md) for the full list. Key upstream projects:
NoSignal OS, Arch Linux, Hyprland, caelestia, Quickshell, SDDM, Limine, Omarchy,
DeckShift, CachyOS chwd (detection method).

## License

MIT — see [LICENSE](LICENSE).
