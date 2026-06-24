# launcher-fix - Super+Space opens the launcher and keeps it open

Bug fix for omarchy-keys (Omarchy keybindings).

## Symptom

`Super+Space` flashes the app launcher open, then it immediately disappears -
it won't stay.

## Root cause

caelestia runs all its binds in a custom Hyprland submap called `global` with a
tap-to-launch system (`modules/Shortcuts.qml`):

```
bindi  = Super, Super_L,  global, caelestia:launcher           # tap Super = launcher
bindin = Super, catchall, global, caelestia:launcherInterrupt  # any key + Super = interrupt
```

- The `launcher` shortcut toggles **on release**, only `if (!launcherInterrupted)`.
- `launcherInterrupt` sets `launcherInterrupted = true`.
- **`catchall` matches Space**, so the same Space press that fires omarchy-keys'
  `Super, Space -> caelestia:launcher` also fires `launcherInterrupt` → the
  launcher is dismissed in the same keystroke.

## Fix

Bind `Super+Space` to toggle the launcher drawer **directly** via IPC, which is
independent of the `launcherInterrupted` flag:

```
unbind = Super, Space
bind = Super, Space, exec, qs -c caelestia ipc call drawers toggle launcher
```

Native Super-tap still opens the launcher (unchanged). No package change; no
edits to the caelestia clone.

## Files

- binds appended to `~/.config/caelestia/hypr-user.conf` (idempotent marked block)

## Install

```sh
sh install-launcher-fix.sh
```

## Builder notes - fold into omarchy-keys

In `omarchy-keys/omarchy-keys-user.conf`, replace
`bind = Super, Space, global, caelestia:launcher` with
`bind = Super, Space, exec, qs -c caelestia ipc call drawers toggle launcher`.
(Upstream-worthy: caelestia's `catchall` interrupt should exclude keys that are
themselves explicitly bound to open the launcher.)
