# HyperWebster — settings app "Updates" page

The Caelestia shell (`caelestia-shell` 2.0.2) settings app has an **Updates**
page under System that's an upstream "under construction" placeholder. HyperWebster
fills it in as the GUI face of `hyperwebster-update`.

## What the page shows / does

- **Pending updates**: official repos (`checkupdates`), AUR (`yay -Qua`),
  Flatpak, and HyperWebster layer migrations not yet applied
- **History**: last full system upgrade (from pacman.log), last check time
- **Check for updates now** — refreshes the counts
- **Update now** — runs `hyperwebster-update` in a floating terminal (`TUI.float`
  rule), so sudo and pacman prompts stay visible and honest

## Architecture (two layers, deliberately)

**Backend (robust, zero fragility):**
- `hyperwebster-update-check` → `~/.local/bin` — writes
  `~/.local/state/hyperwebster/update-status.json`; the page reads this cache so it
  opens instantly
- `hyperwebster-update-check.timer` (systemd user) — refresh every 6h (+5min after
  boot); the JSON is also usable for icon badges later
- Needs `pacman-contrib` (for `checkupdates`)

**UI (a patch on a moving upstream — see caveat):**
- `UpdatesPage.qml` — written in the shell's own idiom (PageBase, InfoRow,
  NavRow, Process/StdioCollector); copied into
  `/etc/xdg/quickshell/caelestia/modules/nexus/pages/` (untracked file —
  pacman upgrades leave it alone)
- `patch-updates-page.sh` — swaps the first System `PlaceholderComp` in
  `PageCompRegistry.qml` for the real page (backs up to `.pre-hyperwebster` once;
  idempotent; **first match only**, so the Plugins stub is untouched)
- **Pacman hook** (`/etc/pacman.d/hooks/hyperwebster-updates-panel.hook`) — shell
  upgrades revert `PageCompRegistry.qml`, so the hook re-runs the patch after
  every `caelestia-shell` install/upgrade

## Caveat for the builder

The QML patch tracks upstream `caelestia-shell` (2.0.2 at time of writing).
If upstream reshapes `PageCompRegistry.qml`, the perl regex won't match — the
patch script then **warns and leaves the file untouched** (settings app keeps
working, page just stays a placeholder). Upstream also has a commented-out
"Display" page and a "Plugins" stub, suggesting they may ship their own pages
eventually; if their Updates page lands, drop this patch and keep the backend.

## Install

```sh
sh ~/Downloads/updates-panel/install-updates-panel.sh   # needs sudo for the patch + hook
```

Then restart the shell (`Ctrl+Super+Alt+R`) and open Settings → Updates.
Also wired into `hyperwebster-update` as migration `1781236800-updates-panel.sh`.

## Packaging

- Add `pacman-contrib` to the package list.
- Bake: `hyperwebster-update-check` (+ enable the user timer), the patched/copied
  QML (or run the patch in the image build), and the pacman hook with the
  user's home path.
- Patch regex targets caelestia-shell 2.0.2.
