# HyperWebster - monitor control with hyprmoncfg

Adds [hyprmoncfg](https://github.com/crmne/hyprmoncfg) (AUR `hyprmoncfg`,
v1.7.0 at time of writing, MIT) - a terminal-first monitor configurator and
auto-switching daemon for Hyprland.

## What a user gets

- **`Super+Ctrl+H`** (Omarchy's "hardware" slot) → spatial layout editor in a
  floating terminal: drag monitors into place, set mode/scale/VRR/mirror/
  transform, press `s` to save a named profile (`desk`, `tv`, …).
- **`hyprmoncfg apply <profile>`** from any terminal.
- **`hyprmoncfgd`** (systemd user service) - applies the right profile
  automatically on monitor hotplug and laptop lid open/close. Profiles match
  on monitor make/model/serial, not unstable connector names.
- Safe apply: reloads Hyprland, verifies, reverts unless confirmed.

## Why it fits HyperWebster

hyprmoncfg writes `~/.config/hypr/monitors.conf` and **refuses to write the
file unless Hyprland actually sources it** - and the HyperWebster base already
sources exactly that file from `hypr-user.conf` (it's the same file
`nwg-displays` wrote). So the include chain is already in place.

**hyprmoncfg replaces nwg-displays** -
it covers layout *and* workspace assignment (nwg-displays' two jobs) and adds
profiles + the daemon; a single writer of `monitors.conf` avoids the two tools
fighting over the file.

## Files

| File | Role |
|------|------|
| `install-monitor-control.sh` | idempotent installer - installs `hyprmoncfg` (bootstraps yay if needed), verifies the `monitors.conf` source line, appends the bind, enables `hyprmoncfgd` |
| `hyprland-monitor-control.conf` | `Super+Ctrl+H` bind → appended to `hypr-user.conf` (reuses the base's `TUI.float` window rule: floating 1100×700) |

```sh
sh ~/Downloads/monitor-control/install-monitor-control.sh
```

Also wired into `hyperwebster-update` as migration `1781233200-monitor-control.sh`.

## Packaging

- Add `hyprmoncfg` to the package list (AUR).
- Enable the user service in the skeleton:
  `systemctl --user enable hyprmoncfgd` (or a presets entry).
- The bind lands via `hypr-user.conf` like the other HyperWebster binds.
- **Remove `nwg-displays` from the package list** (superseded - see above),
  but keep the empty pre-created `monitors.conf` / `workspaces.conf` and
  their `source =` lines.
- Note: the daemon scores **every** profile in
  `~/.config/hyprmoncfg/profiles/` - don't pre-seed junk profiles in the image.
