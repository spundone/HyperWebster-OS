# hypersmooth-display - 120/144 Hz UI tuning

Tuned **Hyprland** animation curves and **caelestia shell** token durations for
high-refresh displays. Ships OOB on fresh installs; safe to delete the sourced
fragment to revert Hyprland-side changes.

## What changes

- `misc { vfr = true }` - variable frame rate (pairs with VRR TVs/monitors)
- Shorter Hyprland animation multipliers (~2-3 frames at 144 Hz)
- `shell-tokens.json` `animDurations` scaled for snappier Quickshell transitions

## Files

- `hypr-hypersmooth.conf` - Hyprland misc + animations block
- Installed under `~/.local/share/hyperwebster/hypersmooth-display/`

## Note

The TV HDR profile (`tv-gaming-display`) also sets `vfr`; both fragments are
compatible. Apply `hyprmoncfg apply tv-gaming-4k` for 4K144 HDR output.
