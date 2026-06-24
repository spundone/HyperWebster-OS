# dashboard-key — Super+D opens the dashboard / calendar

caelestia's calendar lives in its **dashboard**, which by default opens only by
**hovering the top screen edge** (`Config.dashboard.showOnHover` +
`modules/drawers/Interactions.qml`). Easy to miss and fiddly. This adds a
keybind.

| Key | Action |
|-----|--------|
| `Super+D` | Toggle the dashboard (calendar + media/performance widgets) |
| `Super+Shift+D` | Communication special workspace (moved here from `Super+D`) |

`Super+D` was caelestia's `$kbCommunication` (communication scratchpad
workspace). To avoid losing it, it moves to `Super+Shift+D`. The dashboard is
toggled via the drawer IPC (`qs -c caelestia ipc call drawers toggle
dashboard`) — no shell edits, no package, works offline.

## Files

- binds appended to `~/.config/caelestia/hypr-user.conf` (idempotent marked block)

## Install

```sh
sh install-dashboard-key.sh
```

## Builder notes — fold into omarchy-keys

Add to `omarchy-keys/omarchy-keys-user.conf`:
```
unbind = Super, D
bind = Super, D, exec, qs -c caelestia ipc call drawers toggle dashboard
bind = Super+Shift, D, exec, caelestia toggle communication
```
And document `Super+D` (dashboard) + `Super+Shift+D` (communication) in
`HyperWebster-keybindings.md`. The bar's `calendar_month` icon stays decorative
(making it clickable needs a shell-level change, deliberately avoided).
