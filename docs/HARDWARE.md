# HyperWebster hardware guide

HyperWebster OS is an Arch-based desktop flavor tuned for **gaming desktops and
living-room TV setups** rather than a generic minimal live image.

## Recommended hardware profile

| Component | Typical setup | Driver / tooling |
|-----------|---------------|------------------|
| CPU | Modern x86-64 (Zen 2+, Intel 10th gen+) | `linux-cachyos` (CachyOS tier auto-detected) |
| GPU | AMD RDNA 2+ or NVIDIA Turing+ | `mesa` + vendor Vulkan; PCI scan at install |
| Display | 4K HDR TV or monitor (VRR optional) | `hyprmoncfg` profile `tv-gaming-4k` |
| Storage | NVMe (LUKS2 + btrfs) | TPM2 auto-unlock optional at install |
| Boot | UEFI + Limine | UKI snapshots; **Starman Gaming** entry |
| Remote | Tailscale (preinstalled) | `sudo tailscale up` after install |

The installer detects GPUs via PCI vendor ID (`1002` AMD, `10de` NVIDIA,
`8086` Intel) and installs the matching Mesa/Vulkan stack. Desktop sessions use
the amdgpu or nvidia kernel driver with Wayland/Hyprland.

### 4K HDR TV (VRR)

HyperWebster ships a **hyprmoncfg** profile for 4K high-refresh HDR TVs:

```sh
hyprmoncfg apply tv-gaming-4k
```

Edit `~/.config/hyprmoncfg/profiles/tv-gaming-4k` if your HDMI port name differs
(`hyprctl monitors`). The profile sets `3840x2160@144` with `vrr` and `hdr`
when Hyprland and your GPU driver support them.

**Gamescope / Steam session** (Deckify or DeckShift): HDR and VRR are handled
inside the full-screen gamescope session. Env hints live in
`chimera-deckify-gaming/gamescope-hdr.env` (`ENABLE_HDR_WSI`, etc.).

Desktop Wayland HDR on amdgpu is still maturing on some builds; gamescope is the
primary gaming path for HDR output.

### High-refresh displays (120/144 Hz)

HyperWebster enables **variable frame rate** (`misc:vfr`) and scales caelestia
shell animation durations for snappier motion on high-refresh panels. The
`hypersmooth-display` layer ships OOB; optional zephyr overshoot motion is
available via `hyperwebster-zephyr-polish enable`.

### Btrfs snapshots

**btrfs-assistant** (GUI) and **snapper** timeline timers ship out of the box.
`Super+Ctrl+Shift+B` opens snapshot shortcuts; Limine still lists bootable
rollback entries after pacman transactions.

### AMD GPU notes

- RDNA 2+ support tracks Arch `mesa` and the installed kernel (`linux-cachyos` by
  default). After install, keep the system updated (`hyperwebster-update` or
  `sudo pacman -Syu`).
- CachyOS optimized userspace builds are available once online - flip Settings →
  Services → **CachyOS kernel & repos** ON (or `sudo hyperwebster-cachy-repo enable`)
  to run the full `-Suu` conversion; the kernel is already installed.
- **`cachyos-kernel-manager`** is preinstalled for swapping kernel variants
  (`linux-cachyos-lts`, BORE, etc.) or building custom CachyOS kernels.
- ROCm is **not** pre-installed; add it manually only if you need compute
  workloads outside gaming.

### CPU notes

- Zen 2 / Intel 10th gen and newer map to the appropriate **x86-64-v3/v4** CachyOS
  repo tier (auto-detected at install).
- `zram` swap is enabled by default; no dedicated swap partition.
- Power profiles are available from the quick settings panel.

## Encryption

The installer offers **LUKS2** on the root partition (EFI stays unencrypted).

### TPM2 auto-unlock (controller-friendly boot)

When a TPM is present (`/dev/tpmrm0`), the installer asks whether to enroll
**TPM2** via `systemd-cryptenroll` (PCR 7 - Secure Boot state, auto-retry
**7+11** on failure). The LUKS passphrase is sealed in the TPM; cold boot
unlocks without typing when PCRs match.

At install you can set the **LUKS fallback passphrase to match your login
password** so you only remember one secret when TPM unlock is unavailable.

The install passphrase remains a **fallback** if TPM unlock fails (firmware
update, PCR drift, cleared TPM). Re-enroll:

```sh
sudo hyperwebster-luks-tpm-enroll /dev/disk/by-partuuid/YOUR-LUKS-PARTUUID
```

(`hyperwebster-luks-tpm-enroll` rebuilds the initramfs and runs `limine-update` when available.)

#### Diagnostics

```sh
sudo hyperwebster-luks-tpm-status
```

Checks TPM hardware, LUKS tokens, `sd-encrypt` / Plymouth hooks, kernel cmdline,
and suggests fixes. Exit code 1 means something in the TPM chain needs attention;
passphrase unlock should still work.

#### Troubleshooting

| Symptom | What to do |
|---------|------------|
| Passphrase every boot | `hyperwebster-luks-tpm-status` — no TPM2 token? `hyperwebster-luks-tpm-enroll --pcrs 7+11 …` |
| Black screen at unlock | Press **Esc** for TTY fallback once; run `hyperwebster-update` to refresh Plymouth + hooks |
| Prompt times out (~90s) | Ensure cmdline has `rd.luks.options=timeout=0` and `x-systemd.device-timeout=0`; `sudo limine-update` |
| Enrollment failed at install | TPM may be unavailable in the live ISO chroot — enroll after first boot |
| Worked once, fails after BIOS update | PCR drift — passphrase fallback on Plymouth splash; re-enroll with `--pcrs 7+11` |
| Secure Boot disabled | `sudo hyperwebster-luks-tpm-enroll --pcrs 7+11 /dev/disk/by-partuuid/…` |
| Initramfs missing TPM support | Confirm `sd-encrypt` and `plymouth` (before `sd-encrypt`) in `/etc/mkinitcpio.conf` |

Verify TPM: `systemd-cryptenroll --tpm2-device=list` and `tpm2_pcrread sha256:7` (package `tpm2-tools`).

#### Controller / TV setups

When TPM auto-unlock works, cold boot reaches SDDM with no keyboard. When it
fails, Plymouth shows a **graphical passphrase field** on the Starman splash —
plug a **USB keyboard**; game controllers cannot enter the passphrase.

#### Boot flow (LUKS + TPM)

1. **Limine** loads the UKI (kernel + initramfs).
2. **initramfs** - Plymouth starts, then **`sd-encrypt`** / `systemd-cryptsetup`
   reads `/etc/crypttab` and `rd.luks.name=`, tries the TPM2 token first, then
   shows the Plymouth passphrase prompt if needed.
3. **btrfs** - root mounts `@` via `root=UUID=… rootflags=subvol=@`.
4. **Plymouth** - HyperWebster splash until the desktop session starts.
5. **SDDM** - login greeter (or Starman one-shot autologin when armed).

#### Security note

HyperWebster does **not** offer a LUKS keyfile on the EFI System Partition —
the ESP is unencrypted and physical access would bypass encryption. TPM2 +
passphrase fallback is the supported model.

## Gaming boot (Starman)

Limine ships a **Starman (Gaming / Steam)** entry that adds
`hyperwebster.starman=1` to the kernel command line. When a gamescope session
is installed (Deckify/Chimera or DeckShift), this arms one-shot SDDM autologin
into Steam Big Picture - same flow as `Super+Shift+S`, but chosen from the boot
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
- **Optional frosted glass**: on by default; `hyperwebster-blur-toggle disable` for flat panels.
- **Rounded corners**: `hyperwebster-rounding-toggle enable` or Settings → Additions.
