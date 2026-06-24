# limine-uki-dead-entry

The repair script edits the bootloader, so run it with care. Workaround: pick the UKI entry.

## Symptom
After a `hyperwebster-update` that bumped the kernel (7.0.11→7.0.12), selecting
**"HyperWebster OS"** in Limine drops to a **TTY**. Selecting **"Linux"** (the UKI
entry) boots normally.

## Root cause
- `/etc/default/limine` sets **`ENABLE_UKI=yes`**.
- Per `limine-entry-tool.conf:151`: *"Duplicate 'initramfs' and 'vmlinuz' files
  are removed when 'limine-mkinitcpio' or 'limine-update' is run to generate a
  UKI."* So the first kernel update **deletes** `/boot/vmlinuz-linux` and
  `/boot/initramfs-linux.img`.
- But `limine.conf` carries an installer-seeded **first** entry:
  ```
  /HyperWebster (Arch Linux)
      protocol: linux
      path: boot():/vmlinuz-linux
      module_path: boot():/initramfs-linux.img
      …
  ```
  pointing at the now-deleted files. With **no `default_entry`**, this dead
  entry is the **auto-boot default** → TTY.
- The auto-generated UKI entry (`protocol: efi` → `/EFI/Linux/hyperwebster_linux.efi`)
  is correct and bootable - that's the "Linux" entry that worked.

### Evidence
- `vmlinuz-linux` / `initramfs-linux.img`: **absent**.
- Dead entry present in both `limine.conf` and the pre-update `limine.conf.old`
  (shipped from the ISO).
- UKI is **current**: its sha256 equals the freshly-built image - not stale
  (the May-28 mtime is merely preserved). So the UKI is not the problem.
- GPU-agnostic; prior AMD rounds likely never ran a post-install kernel update.

### Secondary risk (NVIDIA-specific) - flag for the builder
The UKI is **139 MB** (NVIDIA driver + GSP firmware; `linux-firmware-nvidia` is
214 MB) on a **511 MB** ESP. limine.conf already shows the live UKI + a history
copy. As more kernel versions / snapshot UKIs accumulate, the ESP can fill, and
then UKI writes *would* genuinely fail (a real stale-UKI scenario). Recommend:
size the ESP ≥1-2 GB on NVIDIA, and/or trim the initramfs (don't embed the full
GSP firmware), and/or keep UKI snapshot history off the ESP.

## Fix
**Durable (builder, do this in the ISO):** don't seed a `protocol: linux` entry
when `ENABLE_UKI=yes`. Either
1. seed the OS entry as `protocol: efi` → `/EFI/Linux/<uki>_linux.efi`, or
2. drop the manual entry and let limine-entry-tool's auto UKI entry be the OS
   entry (name it via `TARGET_OS_NAME`), and
3. set an explicit **`default_entry`** to the UKI so auto-boot never lands on a
   bad entry.

**This component (repair an installed system):** `fix-limine-uki-entry.sh`
(root, idempotent, backs up limine.conf) rewrites the seeded entry's body from
`protocol: linux` + `vmlinuz-linux` to `protocol: efi` + the UKI, keeping the
label (stays first = default) and the cmdline. No-op if already fixed; refuses
if the UKI file is missing.

## Verify
```
grep -A3 'HyperWebster (Arch Linux)' /boot/limine.conf   # protocol: efi + UKI path
```
Then reboot and confirm the top/default entry boots to the desktop.

## Files
- `fix-limine-uki-entry.sh` - idempotent root repair.
- `migrations/1781434800-limine-uki-dead-entry.sh` - delegates to it.
