# xdg-terminal-exec-handler

## Symptom
A critical desktop notification at/after login:

```
app2unit: Error - Executable not found: 'xdg-terminal-exec'
```

Launching any `Terminal=true` `.desktop` entry through `app2unit` - or
`app2unit -T` - silently fails. `app2unit` is the launcher behind many HyperWebster
binds (terminal, browser, editor, file explorer, pavucontrol…) and the
Caelestia launcher's app-open path, so this is user-visible.

## Cause
`app2unit` hardcodes its terminal handler:

```
A2U__TERMINAL_HANDLER=xdg-terminal-exec
```

…but HyperWebster never shipped `xdg-terminal-exec` (not in PATH, not a package),
and there is no `~/.config/xdg-terminals.list`. Reproduce:

```
$ app2unit -T -- true
Terminal launch requested but 'xdg-terminal-exec' is unavailable!
```

Default terminal on this build is `kitty`.

## Fix
Two layers:

1. **Preferred (builder):** add the freedesktop **`xdg-terminal-exec`** package
   to the ISO package set and ship a system `xdg-terminals.list`
   (`/etc/xdg/xdg-terminals.list` = `kitty.desktop`). That makes app2unit's
   default handler resolve properly for everyone.
2. **Offline fallback (this component):** `install-xdg-terminal-exec-handler.sh`
   drops a tiny `xdg-terminal-exec` shim into `~/.local/bin` that execs the
   configured terminal (`$TERMINAL`, else `kitty`) per the xdg-terminal-exec
   calling convention, and seeds `~/.config/xdg-terminals.list`. The installer
   is idempotent and **self-correcting**: if the real package later lands in a
   system bin, it removes the shim so it no longer shadows it.

## Files
- `xdg-terminal-exec` - the shim.
- `install-xdg-terminal-exec-handler.sh` - idempotent installer.
- `migrations/1781427600-xdg-terminal-exec-handler.sh` - delegates to it.

## Verify
```
app2unit -T -- true        # exits 0, no "unavailable" error
```

## Notes / limitation
The shim passes args straight through to the terminal; it does not parse
`xdg-terminal-exec`-specific options (`--app-id=` etc.). For full fidelity ship
the real package - the shim is the offline stop-gap. No secrets, no per-user
identity; honours `$TERMINAL`.
