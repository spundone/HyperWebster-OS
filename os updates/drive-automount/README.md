# drive-automount - premount data drives at boot

On boot, discovers **non-system** block devices with a supported filesystem and
mounts them under `/mnt/<label>` (or `/mnt/disk-<uuid8>` when unlabeled).

## Behaviour

- Writes `/etc/fstab.d/99-hyperwebster-automount.conf` (regenerated each boot).
- Uses `nofail` and `x-systemd.device-timeout=5` so a missing drive never blocks boot.
- Skips: root, `/boot`, `/home`, snapshots, log subvolumes, swap, LUKS headers,
  loop/sr/zram, and EFI vfat partitions.
- Supported types: `ext4`, `btrfs`, `xfs`, `vfat` (non-EFI), `exfat`, `ntfs`/`ntfs3`, `f2fs`.

Install `ntfs-3g` / `exfatprogs` from the repos if you attach NTFS/exFAT game libraries.

## Files

```
hyperwebster-drive-automount          -> /usr/local/bin
hyperwebster-drive-automount.service  -> /etc/systemd/system
install-drive-automount.sh            idempotent installer (sudo)
```

## Manual refresh

```sh
sudo hyperwebster-drive-automount
```
