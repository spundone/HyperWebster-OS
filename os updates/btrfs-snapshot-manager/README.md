# btrfs-snapshot-manager - CachyOS-style snapshot GUI

Ships **btrfs-assistant** (AUR) for managing btrfs subvolumes and Snapper
snapshots, plus **btrfsmaintenance** scrub/balance timers. HyperWebster already
uses snapper + snap-pac + Limine bootable snapshots; this layer adds the GUI and
timeline timers CachyOS users expect.

## Packages

- `btrfs-assistant-git` - snapshot/subvolume GUI (built offline into the ISO repo)
- `btrfsmaintenance` - periodic btrfs scrub (Arch extra)

## Commands

| Command | Action |
|---------|--------|
| `btrfs-assistant` | Launch the snapshot manager GUI |
| `hyperwebster-snapshots` | Fuzzel menu: GUI, snapper list, update with snapshot |

## Snapper timeline

Install enables `snapper-timeline.timer` and `snapper-cleanup.timer` with
conservative retention (10 hourly, 7 daily). Pre/post pacman snapshots via
snap-pac are unchanged.

## Keybind

`Super+Ctrl+Shift+B` opens `hyperwebster-snapshots` (B for btrfs).
