# sudo-timed-nopasswd — time-boxed passwordless sudo ("sudoless" mode)

Writes to `/usr/local/bin`, installs a systemd unit, and patches caelestia
— all need root. Install with the command below.

## What it is
A Settings → Services toggle (and a CLI) that grants the user **`NOPASSWD: ALL`
for 15 minutes**, then automatically reverts. For batches of admin work without
re-typing your password each time — bounded so it can't be left on forever.

Inspired by Omarchy's install-time `/etc/sudoers.d/first-run` (which is just
`$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl`, removed after first-run — see
omarchy issue #5708). This is the deliberate, user-triggered, time-boxed,
full-`ALL` version.

## Pieces
- **`hyperwebster-sudo-toggle`** → `/usr/local/bin` — `enable` / `disable` / `status`.
- **`hyperwebster-sudoless-boot-clean.service`** (enabled) — removes the drop-in on
  every boot (reboot safety net; see below).
- **`SudoToggleRow.qml`** → `nexus/common/` (untracked, survives upgrades).
- **`patch-servicespage.sh`** — inserts the toggle into `ServicesPage.qml`
  (re-applied by the caelestia-shell pacman hook, like the Additions/Updates patches).

## How it works
- **enable** (root; you authenticate ONCE): validates a drop-in with
  `visudo -cf` *before* installing it (a broken sudoers never reaches
  `/etc/sudoers.d`), writes `/etc/sudoers.d/01-hyperwebster-sudoless`
  (`<user> ALL=(ALL:ALL) NOPASSWD: ALL`, mode 0440), stamps
  `/run/hyperwebster-sudoless.stamp` (world-readable, for `status`), and arms a
  root-owned transient timer: `systemd-run --on-active=15min … disable`.
- **disable**: cancels the timer, removes the drop-in + stamp. Inside the window
  `sudo -n` runs it without a prompt; the panel's "off" uses exactly that.
- **status**: reads only the `/run` stamp → no root, so the toggle can poll it
  every 5 s and show minutes remaining.

## Safety
- `visudo -cf` validation before install — never installs a malformed sudoers.
- Auto-revert after 15 min via a root systemd timer (no password needed).
- **Reboot net:** transient timers don't survive a reboot but the `/etc`
  drop-in would — so `hyperwebster-sudoless-boot-clean.service` removes it on every
  boot. A reboot always ends the sudoless session.
- Full `NOPASSWD: ALL` is broad **by design** (the requested "run sudoless"),
  with the 15-min window + reboot net as the bound. If you want it narrower,
  change the drop-in body in `hyperwebster-sudo-toggle` (e.g. limit to
  `/usr/bin/systemctl, /usr/bin/pacman`).

## Install (root)
```
sudo sh ~/.local/share/hyperwebster/sudo-timed-nopasswd/install-sudo-timed-nopasswd.sh
```
Then reload caelestia (or log out/in) so the new toggle/QML loads.

## Use
- Settings → Services → **Passwordless sudo (15 min)**: on opens a small
  floating terminal for your password (once); off reverts immediately.
- Or terminal: `sudo hyperwebster-sudo-toggle enable` / `disable`,
  `hyperwebster-sudo-toggle status`.

## Auto-revert
The 15-min `systemd-run` timer fires on schedule to revert the drop-in.
`disable` removes the drop-in/stamp **first**, then touches units, and
`cancel_timer` stops **only the `.timer`**, never the `.service` — this avoids
the revert service stopping itself (getting SIGTERM'd) before the `rm` runs.

`disable` also clears the user's cached sudo **timestamp**
(`/run/sudo/ts/<user>`) — sudo caches a ticket ~15 min independently of the
drop-in, so without this a sudo run just before revert would stay passwordless
past the window.

## QML toggle
The Settings → Services row toggles sudoless mode. Toggle ON → floating
terminal → password → drop-in installed, 15-min timer armed, status `active 15`.
Toggle OFF → immediate revert: drop-in + stamp removed, timer disarmed, sudo
cache cleared, `sudo` prompts again.

## Files
- `hyperwebster-sudo-toggle`, `hyperwebster-sudoless-boot-clean.service`,
  `install-sudo-timed-nopasswd.sh`, `SudoToggleRow.qml`,
  `patch-servicespage.sh`, `migrations/1781456400-sudo-timed-nopasswd.sh`.
