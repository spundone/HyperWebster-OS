# monitor-control-fix - make saved hyprmoncfg profiles actually apply

Bug fix for monitor-control (hyprmoncfg). Saving a monitor profile in the
`Super+Ctrl+H` TUI had **no effect**: `~/.config/hypr/monitors.conf` stayed
empty and the layout/scale never changed.

## Root cause

`hyprmoncfg` writes `monitors.conf` only if it can confirm that file is
`source`d - and it checks **only the single file passed as `--hypr-config`**
(default `hyprland.conf`). On caelestia the source line lives in
`hypr-user.conf`, and `hyprland.conf` includes it **indirectly**:

```
hyprland.conf  ──source = $cConf/hypr-user.conf──▶  hypr-user.conf
                                                      └─source = ~/.config/hypr/monitors.conf
```

hyprmoncfg does not follow that nested include (nor expand the `$cConf`
variable), so it reports *"monitors.conf is not sourced by hyprland.conf"* and
aborts. The daemon log shows it even finds the right profile first:

```
best profile "profile-…" score=100
apply failed: …/monitors.conf is not sourced by …/hyprland.conf
```

## Fix

Point hyprmoncfg's verification at `hypr-user.conf` (which sources
`monitors.conf` directly), with an **absolute** `--monitors-conf` (otherwise it
resolves relative to the `--hypr-config` directory). Applied in two places:

- **Daemon** - systemd user drop-in `hyprmoncfgd.service.d/override.conf`
  re-runs `hyprmoncfgd` with the two flags (using the `%h` home specifier).
  The drop-in also gates startup with an `ExecStartPre` loop: at login the
  daemon raced Hyprland's startup - `hyprctl
  instances -j` is momentarily invalid JSON, the first profile apply failed
  and flashed an error notification (the daemon's own 5s retry then
  succeeded). The gate waits (≤30s) for the instances JSON to parse before
  the daemon starts, so no failed first attempt and no notification.
- **TUI** - `Super+Ctrl+H` rebound to `hyprmoncfg --hypr-config … --monitors-conf …`.

No package change; no edits to the forbidden caelestia clone files.

## Files

- `hyprmoncfgd-override.conf` → `~/.config/systemd/user/hyprmoncfgd.service.d/override.conf`
- binds appended to `~/.config/caelestia/hypr-user.conf` (idempotent marked block)

## Install

```sh
sh install-monitor-control-fix.sh
```

## Builder notes - fold into monitor-control

Cleanest is to **bake the two flags into monitor-control directly** rather than ship a
separate fix:
- Add the `hyprmoncfgd.service.d/override.conf` drop-in to the image (or patch
  the upstream unit / package the daemon with these defaults).
- Make the `Super+Ctrl+H` bind in `monitor-control/hyprland-monitor-control.conf`
  include `--hypr-config $HOME/.config/caelestia/hypr-user.conf --monitors-conf
  $HOME/.config/hypr/monitors.conf`.
- Upstream-worthy: hyprmoncfg should follow nested `source =` includes and
  expand Hyprland variables when locating the monitors.conf source line.
