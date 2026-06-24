# HyperWebster hardware profile

HyperWebster OS is a **personal** Arch desktop flavor, tuned for a dedicated
gaming workstation rather than a generic live image.

## Primary target machine

| Component | Hardware | Driver stack |
|-----------|----------|--------------|
| CPU | AMD Ryzen 7 5700X3D | `linux-cachyos` (x86-64-v3 tier) — default OOB |
| GPU | AMD Radeon RX 9070 (RDNA 4) | `mesa`, `vulkan-radeon`, kernel `amdgpu` |
| Display | TCL T89C TV (4K @ 144 Hz, HDR, VRR) | `hyprmoncfg` profile `tcl-t89c-tv` |
| Storage | NVMe (LUKS2 + btrfs) | TPM2 auto-unlock optional at install |
| Boot | UEFI + Limine | UKI snapshots; **Starman Gaming** entry |
| Remote | Tailscale (preinstalled) | `sudo tailscale up` after install |

The installer detects AMD GPUs via PCI vendor `1002` and installs
`mesa` + `vulkan-radeon`. Desktop sessions use the amdgpu kernel driver with
Wayland/Hyprland — no NVIDIA hybrid logic applies on this box.

### TCL T89C TV (4K144 HDR VRR)

HyperWebster ships a **hyprmoncfg** profile for the primary TV:

```sh
hyprmoncfg apply tcl-t89c-tv
```

Edit `~/.config/hyprmoncfg/profiles/tcl-t89c-tv` if your HDMI port name differs
(`hyprctl monitors`). The profile sets `3840x2160@144` with `vrr` and `hdr`
when Hyprland/amdgpu support them on your build.

**Gamescope / Steam session** (Deckify or DeckShift): HDR and VRR are handled
inside the full-screen gamescope session. Env hints live in
`chimera-deckify-gaming/gamescope-hdr.env` (`ENABLE_HDR_WSI`, etc.).

**Needs real hardware validation** on the TCL T89C — desktop Wayland HDR on
amdgpu is still maturing; gamescope is the primary gaming path.

### RX 9070 notes

- RDNA 4 support tracks Arch `mesa` and the installed kernel (`linux-cachyos` by
  default). After install, keep the system updated (`hyperwebster-update` or
  `sudo pacman -Syu`).
- CachyOS optimized userspace builds are available once online — flip Settings →
  Services → **CachyOS kernel & repos** ON (or `sudo hyperwebster-cachy-repo enable`)
  to run the full `-Suu` conversion; the kernel is already installed.
- **`cachyos-kernel-manager`** is preinstalled for swapping kernel variants
  (`linux-cachyos-lts`, BORE, etc.) or building custom CachyOS kernels.
- ROCm is **not** pre-installed; add it manually only if you need compute
  workloads outside gaming.

### Ryzen 5700X3D notes

- Zen 3 → **x86-64-v3** CachyOS repo tier (auto-detected at install).
- 3D V-Cache benefits most games without special tuning.
- `zram` swap is enabled by default; no dedicated swap partition.
- Power profiles are available from the quick settings panel.

## Encryption

The installer offers **LUKS2** on the root partition (EFI stays unencrypted).

### TPM2 auto-unlock (controller-friendly boot)

When a TPM is present (`/dev/tpmrm0`), the installer asks whether to enroll
**TPM2** via `systemd-cryptenroll` (PCR 7 — Secure Boot state). Cold boot then
unlocks without typing the passphrase when PCRs match.

The install passphrase remains a **fallback** if TPM unlock fails (firmware
update, PCR drift, cleared TPM). Re-enroll:

```sh
sudo hyperwebster-luks-tpm-enroll /dev/disk/by-partuuid/YOUR-LUKS-PARTUUID
sudo mkinitcpio -P
```

**Needs real hardware testing** — verify TPM PCR policy on your motherboard and
that Plymouth/SDDM still flow cleanly after auto-unlock.

## Gaming boot (Starman)

Limine ships a **Starman (Gaming / Steam)** entry that adds
`hyperwebster.starman=1` to the kernel command line. When a gamescope session
is installed (Deckify/Chimera or DeckShift), this arms one-shot SDDM autologin
into Steam Big Picture — same flow as `Super+Shift+S`, but chosen from the boot
menu.

### Gaming stacks (pick one)

| Stack | Install |
|-------|---------|
| **Deckify / Chimera** (recommended for Starman) | Settings → Additions → Deckify / Chimera Gaming, or `hyperwebster-deckify-install` |
| **DeckShift** | Settings → Additions → DeckShift Gaming Mode |

Both use the same session-switch overlay (`deckshift-login`) for password-at-boot
with one-shot autologin on switch.

## Tailscale remoting

`tailscale` and `tailscaled` ship in the base image. After install:

```sh
sudo tailscale up
# optional: sudo tailscale up --ssh
```

MagicDNS and subnet routes are configured in the [Tailscale admin console](https://login.tailscale.com/admin).

## Data drive automount

Extra internal or USB data drives are **premounted at boot** under
`/mnt/<label>` (see [drive-automount](../os%20updates/drive-automount/README.md)).
System disks (root, EFI, LUKS, home subvolume) are never touched. Entries use
`nofail` so a missing drive never blocks boot.

Supported filesystems: ext4, btrfs, xfs, exfat, ntfs, f2fs, and non-EFI vfat.
Run `sudo hyperwebster-drive-automount` after hot-plugging a new disk.

## Desktop polish

- **Raycast-like launcher**: fuzzy search via Super+Space (`hyperwebster-launcher-raycast` refreshes settings).
- **Optional frosted glass**: `hyperwebster-blur-toggle enable` (default stays flat/restrained).
