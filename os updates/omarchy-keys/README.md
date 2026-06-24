# HyperWebster — Omarchy default keybindings

Remaps the HyperWebster/Caelestia keybindings to match **Omarchy's defaults**
(basecamp/omarchy — current Lua-based config:
`default/hypr/bindings/{tiling-v2,utilities,media,clipboard}.lua` +
`config/hypr/bindings.lua`).

Rule applied: **where an action exists in both worlds, it gets Omarchy's key.**
Caelestia-only features keep their keys (moved only if Omarchy claims the key);
Omarchy-only features (walker menus, waybar, webapps, reminders, …) have no
HyperWebster equivalent and are not ported.

## How it's implemented

| File | Appended to | Mechanism |
|------|-------------|-----------|
| `omarchy-keys-vars.conf` | `~/.config/caelestia/hypr-vars.conf` | redefines `$kb*` variables (sourced before `keybinds.conf` consumes them) |
| `omarchy-keys-user.conf` | `~/.config/caelestia/hypr-user.conf` | `unbind` + `bind` for hardcoded/conflicting keys (parsed last, so it wins) |

The installer also edits the existing overview bind in `hypr-user.conf`:
`Super+Tab` → `Super+Grave` (Omarchy uses `Super+Tab` for next-workspace).
Both files survive Caelestia updates (only the `hypr` symlink target is
overwritten). Installer: `install-omarchy-keys.sh` (idempotent).

## The mapping

| Action | Omarchy key (now active) | Old HyperWebster key |
|--------|--------------------------|----------------|
| Terminal | `Super+Return` | `Super+T` |
| Browser | `Super+Shift+Return`, `Super+Shift+B` | `Super+W` |
| Editor | `Super+Shift+N` | `Super+C` |
| File manager | `Super+Shift+F` | `Super+E` |
| Close window | `Super+W` | `Super+Q` |
| Toggle floating | `Super+T` | `Super+Alt+Space` |
| Fullscreen / maximized | `Super+F` / `Super+Alt+F` | unchanged |
| Pseudo window | `Super+P` | (new) |
| Toggle split | `Super+J` | (new) |
| Pin window ("pop out") | `Super+O` | `Super+P` |
| Toggle group | `Super+G` | `Super+Comma` |
| Ungroup window | `Super+Alt+G` | `Super+U` |
| Cycle in group | `Super+Alt+Tab` / `+Shift` | `Alt+Tab` / `Shift+Alt+Tab` |
| Cycle windows | `Alt+Tab` / `Shift+Alt+Tab` | (was group cycling) |
| Go to workspace 1–10 | `Super+1…0` | unchanged |
| Move window to workspace | `Super+Shift+1…0` (keycodes) | `Super+Alt+1…0` (kept as alias) |
| Next / prev workspace | `Super+Tab` / `Super+Shift+Tab` | `Ctrl+Super+→/←` (kept) |
| Former workspace | `Super+Ctrl+Tab` | (new) |
| Scratchpad / move to it | `Super+S` / `Super+Alt+S` | unchanged |
| Launcher | `Super+Space` (Super-tap kept) | tap `Super` |
| **Show key bindings** | `Super+K` | `Super+/` (kept as alias, +F1) |
| Lock screen | `Super+Ctrl+L` | `Super+L` |
| Session/system menu | `Super+Escape` | `Ctrl+Alt+Delete` (kept as alias) |
| Clear notifications | `Super+Shift+Comma` | `Ctrl+Alt+C` (kept as alias) |
| Emoji picker | `Super+Ctrl+E` | `Super+Period` (kept) |
| Clipboard manager | `Super+Ctrl+V` | `Super+V` (kept) |
| Audio controls | `Super+Ctrl+A` | `Ctrl+Alt+V` (kept) |
| Activity (system monitor) | `Super+Ctrl+T` | `Ctrl+Shift+Escape` (kept) |
| Music | `Super+Shift+M` | `Super+M` (kept) |
| Color picker | `Super+Print` | `Super+Shift+C` (kept) |
| Screenshot | `Print` | unchanged |
| GitHub Desktop | `Super+Shift+G` | `Super+G` |
| Caelestia panels (showall) | `Super+Ctrl+K` | `Super+K` |
| Overview sidecar (HyperWebster) | `Super+Grave` | `Super+Tab` |
| Shelly app store | `Super+I` | unchanged |

## Deliberate deviations / not ported

- **Universal copy/paste/cut** (Omarchy `Super+C/V/X` → synthesized
  Ctrl+Insert etc.): skipped — needs Omarchy's send_shortcut stuck-key
  workaround, and `Super+V` stays the clipboard manager here.
- **Workspace move silently** (`Super+Shift+Alt+#`): skipped — Caelestia's
  `wsaction` group logic has no silent variant.
- `Ctrl+Super+←/→` stays prev/next workspace (Caelestia) rather than Omarchy's
  grouped-window focus; `Ctrl+Alt+Tab` still changes the active group member.
- Omarchy resize keys (`Super+code:20/21` x-axis) skipped — Caelestia's
  `Super+Minus/Equal` (±width) and `Super+Shift+Minus/Equal` (±height) kept.
- Group lock (`Super+Shift+Comma`) dropped (key now = clear notifications).
- Mute alias `Super+Shift+M` dropped (key now = music); `XF86AudioMute` works.
- Keys left unbound after the moves: `Super+Q`, `Super+C`, `Super+E`,
  `Super+U`, `Super+Comma`, `Super+L`, `Super+Alt+Space`.
- Omarchy-only, no equivalent: walker/omarchy menus, waybar toggles, theme/
  background switchers, webapps, reminders, OCR, share, transcode, nightlight,
  zoom, monitor scaling.

`../HyperWebster-keybindings.md` is rewritten to the new map, so the `Super+K`
cheatsheet reflects all of this automatically.
