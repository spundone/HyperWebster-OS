# HyperWebster hardware profile

HyperWebster OS is a **personal** Arch desktop flavor, tuned for a dedicated
gaming workstation rather than a generic live image.

## Primary target machine

| Component | Hardware | Driver stack |
|-----------|----------|--------------|
| CPU | AMD Ryzen 7 5700X3D | `linux` / optional `linux-cachyos` via Settings toggle |
| GPU | AMD Radeon RX 9070 (RDNA 4) | `mesa`, `vulkan-radeon`, kernel `amdgpu` |
| Storage | NVMe (LUKS2 + btrfs) | Full-disk encryption on the root partition |
| Boot | UEFI + Limine | UKI snapshots; optional **Starman Gaming** entry |

The installer detects AMD GPUs via PCI vendor `1002` and installs
`mesa` + `vulkan-radeon`. Desktop sessions use the amdgpu kernel driver with
Wayland/Hyprland — no NVIDIA hybrid logic applies on this box.

### RX 9070 notes

- RDNA 4 support tracks Arch `mesa` and `linux` kernel versions. After install,
  keep the system updated (`hyperwebster-update` or `sudo pacman -Syu`).
- For bleeding-edge Mesa fixes, the optional CachyOS repo toggle in Settings
  can switch to optimized builds (reboot required).
- ROCm is **not** pre-installed; add it manually only if you need compute
  workloads outside gaming.

### Ryzen 5700X3D notes

- 3D V-Cache benefits most games without special tuning.
- `zram` swap is enabled by default; no dedicated swap partition.
- Power profiles are available from the quick settings panel.

## Encryption

The installer offers **LUKS2** on the root partition (EFI stays unencrypted).
Passphrase is prompted at install time and required on every cold boot before
Plymouth/SDDM.

## Gaming boot (Starman)

Limine ships a **Starman (Gaming / Steam)** entry that adds
`hyperwebster.starman=1` to the kernel command line. When DeckShift is
installed, this arms a one-shot SDDM autologin into the gamescope Steam session
— same flow as `Super+Shift+S`, but chosen from the boot menu.

Install DeckShift once after setup (Settings → Additions or manual), then reboot
via the Starman entry when you want a console-style Steam session without
logging into the desktop first.

## Data drive automount

Extra internal or USB data drives are **premounted at boot** under
`/mnt/<label>` (see [drive-automount](../os%20updates/drive-automount/README.md)).
System disks (root, EFI, LUKS, home subvolume) are never touched. Entries use
`nofail` so a missing drive never blocks boot.

Supported filesystems: ext4, btrfs, xfs, exfat, ntfs, f2fs, and non-EFI vfat.
Run `sudo hyperwebster-drive-automount` after hot-plugging a new disk.
