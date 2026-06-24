# super-clipboard - universal Super+C / Super+V copy & paste

Makes a single, OS-wide copy/paste pair that works the same everywhere:

| Key | Action |
|-----|--------|
| `Super+C` | Copy (terminals → Ctrl+Shift+C, GUI apps → Ctrl+C) |
| `Super+V` | Paste (terminals → Ctrl+Shift+V, GUI apps → Ctrl+V) |
| `Super+Ctrl+V` | Clipboard **history** (unchanged) |
| `Super+Alt+V` | Clipboard history - delete-entry mode (unchanged) |

## How it works

Wayland has no global copy/paste; each application owns its own shortcut, and
terminals deliberately differ (Ctrl+C = SIGINT). `super-copy` / `super-paste`
read the focused window's class (`hyprctl activewindow`) and forward the
correct real shortcut to it using Hyprland's built-in **`sendshortcut`**
dispatcher.

**No external dependencies** - no `ydotool`/`wtype`, no `uinput` permissions,
no daemon. Just `hyprctl` + `jq` (both already present).

## Files

- `super-copy`, `super-paste` → installed to `~/.local/bin`
- binds appended to `~/.config/caelestia/hypr-user.conf` (idempotent, marked
  block; `unbind = SUPER, V` removes the stock history bind first)

## Install

```sh
sh install-super-clipboard.sh
```

Idempotent. Re-running only refreshes the scripts; the conf block is added once.

## Builder notes

- No package delta. Relies on `hyprctl`, `jq`, and the `sendshortcut`
  dispatcher (Hyprland ≥ 0.25-era; present on 0.55.x).
- If baking binds directly instead of running the installer, write the marked
  block above into the shipped `hypr-user.conf` and drop `super-copy`/
  `super-paste` into `~/.local/bin`.
- The terminal class-list is a substring match (`*term*` etc.); extend
  `super-copy`/`super-paste` if you add a terminal whose class doesn't match.
