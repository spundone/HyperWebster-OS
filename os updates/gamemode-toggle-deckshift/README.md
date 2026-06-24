# gamemode-toggle-deckshift - Game Mode toggle launches DeckShift

Companion to `gaming-key-guard` (which does the Super+Shift+S keybind). Patches
the package-owned hyperwebster-shell file; the canonical fix is in the fork.

## Request
The utilities **Game Mode** button (gamepad icon) should launch the DeckShift
gaming session when DeckShift is installed, and do nothing otherwise. Previously
it ran caelestia's cosmetic Game Mode (disable Hyprland animations/blur/gaps).

## Change
`modules/utilities/cards/Toggles.qml`, the `gameMode` `DelegateChoice`:

before
```qml
delegate: Toggle {
    icon: "gamepad"
    checked: GameMode.enabled
    onClicked: GameMode.enabled = !GameMode.enabled
}
```
after (hardened)
```qml
delegate: Toggle {
    id: gmTog
    property bool launching: false
    icon: "gamepad"
    disabled: launching
    onClicked: {
        if (gmTog.launching) return;
        gmTog.launching = true;
        gmTog.internalChecked = false; // don't latch "on" - it's a launcher
        relockTimer.start();
        Quickshell.execDetached(["sh", "-c", "[ -x /usr/local/bin/switch-to-gaming ] && [ -f /usr/share/wayland-sessions/gamescope-session-steam-nm.desktop ] && exec /usr/local/bin/switch-to-gaming"]);
    }
    Timer { id: relockTimer; interval: 5000; onTriggered: gmTog.launching = false }
}
```
- **Kept styled as an off-toggle** (default `isToggle: true`, no `checked`) so it
  keeps the muted/outline look of the other toggles. An earlier version set
  `isToggle: false`, which flipped the icon to filled/accent - that was the
  reported "changed colour"; reverted. `internalChecked` is reset to false on
  click so the launcher never latches "on".
- **Debounced.** A fast double-click previously fired `switch-to-gaming` twice →
  two `systemctl restart sddm` calls → the first restart consumed the one-shot
  autologin marker and the second fell back to the password greeter (the reported
  "takes you to the login screen, not gamescope"). The `launching` guard +
  `disabled` + 5 s `relockTimer` ensure one launch per press.
- The `sh -c '… && … && exec switch-to-gaming'` guard mirrors the Super+Shift+S
  bind and the deckshift-login install-check: nothing happens if DeckShift is absent.
- Adds `import Quickshell` (for `execDetached`; the file only had
  `Quickshell.Bluetooth`). `GameMode` (from `qs.services`) is no longer referenced
  here - the cosmetic Game Mode is still available via its IPC (`gameMode` target)
  if a future build wants to re-expose it elsewhere.
- **Hidden when DeckShift isn't installed.** A `deckshiftProbe` Process
  (`test -f /usr/share/wayland-sessions/gamescope-session-steam-nm.desktop`) sets
  `root.deckshiftInstalled` at load, and the `quickToggles` filter drops the
  `gameMode` entry when it's false (same pattern as the existing `vpn` special-case)
  - so the tile cleanly leaves the grid (no dead button, no gap) on non-gaming
  boxes, and appears once DeckShift is installed (after a shell reload). Needs
  `import Quickshell.Io` for `Process`.

## Pieces / integration
1. **`Toggles.qml`** - corrected file (drop-in for
   `modules/utilities/cards/Toggles.qml` in the hyperwebster-shell fork). Rebuild the
   package; set `HYPERWEBSTER_SKIP_SHELL_PATCH` for the build.
2. **`install-gamemode-toggle-deckshift.sh`** - idempotent fallback patch (backup +
   overwrite). Reverted by the next hyperwebster-shell upgrade (which carries the fix).
3. **`1781478000-gamemode-toggle-deckshift.sh`** → `hyperwebster-update/migrations/`
   (delegates via `$HYPERWEBSTER_SRC`).

**Shell restart required:** `qs -c caelestia -n -d` disables the file watcher, so
the patched file is not hot-reloaded - restart the shell (**Ctrl+Super+Alt+R**) or
log out/in after patching.

## Apply on this box now (needs root)
```sh
sudo sh ~/hyperwebster-handoff/gamemode-toggle-deckshift/install-gamemode-toggle-deckshift.sh
```
then **Ctrl+Super+Alt+R**.
