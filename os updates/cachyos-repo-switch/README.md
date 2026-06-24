# cachyos-repo-switch — CachyOS optimized repos + kernel switch (sudoless, auto-tier)

Works **both directions** — ON → reboot into `linux-cachyos`; OFF → reboot back to stock.

## What it is
One toggle in **Settings → Services** (under "Passwordless sudo") that switches the
system **to/from** CachyOS-optimized builds **and** the `linux-cachyos` kernel —
passwordless, auto-detecting the best x86-64 tier (v4 > v3), fully unattended
(`--noconfirm`). Refuses below x86-64-v3.

## Pieces
- **`hyperwebster-cachy-repo`** → `/usr/local/bin` — `detect` / `status` / `enable` /
  `disable` (+ `--dry-run`).
- **`02-hyperwebster-cachy`** → `/etc/sudoers.d` (0440, `visudo -c`-validated at install)
  — `%wheel` NOPASSWD, pinned to the four exact subcommands of the fixed helper.
- **`CachyRepoToggleRow.qml`** → `nexus/common/` — baked into the pinned
  hyperwebster-shell fork; this copy + `patch-servicespage.sh` are the migration
  path for old stock-caelestia installs.
- **`patch-servicespage.sh`** — inserts the toggle into `ServicesPage.qml` (only used
  by the hyperwebster-update migration; the builder skips it via HYPERWEBSTER_SKIP_SHELL_PATCH).

## Two design fixes baked in — DO NOT reintroduce the bugs
1. **Architecture (critical).** CachyOS v3/v4 packages have arch `x86_64_v3`/`x86_64_v4`.
   Upstream relies on its OWN pacman (reads `Architecture = auto` as "include v3/v4").
   We keep **stock pacman** (reads `auto` as just `x86_64`) → it would arch-reject every
   v3/v4 package and the conversion would silently do nothing. So `enable` sets
   `Architecture` EXPLICITLY to the tier (`x86_64 x86_64_v3 x86_64_v4` for v4,
   `x86_64 x86_64_v3` for v3); `disable` restores `Architecture = auto`.
2. **Targeted revert (no whole-base pull).** `disable` reinstalls ONLY packages whose
   local-DB `Packager` is `CachyOS …` (excluding the cachy keyring/mirrorlist pkgs,
   removed separately) — never the full base. Nothing converted ⇒ nothing to do.

## Why stock pacman (and `--ignore pacman`)
Upstream `cachyos-repo.sh` is interactive, ends with `pacman -Syu`, and swaps in a
CachyOS `pacman`. We reuse its signed keyring/mirrorlists + `.awk` stanza files but
drive pacman ourselves (stock, unattended). The CachyOS `pacman` build stamps an
`%INSTALLED_DB%` key into the local DB that stock pacman then warns about on every op,
so `enable` runs `pacman -Suu --ignore pacman` to pin pacman stock. **Keep that flag.**

## Kernel guard
`enable` installs `linux-cachyos` + `-headers` (the limine-mkinitcpio-hook generates
the boot entry; stock `linux` stays as a fallback). `disable` removes the cachy kernel
ONLY after confirming stock `linux` is installed — never strips the last bootable
kernel. A **reboot** is needed after ON (to run the new kernel) and after OFF (to leave
it); pick the entry at the Limine menu.

## Live-fetch vs vendored (build decision: LIVE-FETCH)
`enable`/`disable` fetch upstream `cachyos-repo.tar.xz` (keyring + mirrorlists + `.awk`).
Enabling CachyOS is inherently online (it pulls optimized builds + the kernel from
CachyOS mirrors), so there is no offline scenario to vendor for — live-fetch needs no
bundled artifacts and never goes stale. If a future air-gapped image needs it, vendor
the tarball and drop the fetch in `fetch_upstream()`.

## CachyOS-exclusive packages don't revert (by design)
Any package with no stock equivalent stays a CachyOS build on OFF and is reported, not
removed (e.g. `quickshell-git`, `gamescope-session-git` —
harmless; self-clear on the next `yay -Sua`). The `linux-cachyos` kernel is the one
exception (removed explicitly, guarded as above). Snapshot entries keep historical
cachy UKIs under the Snapshots submenu (cosmetic; age out as snapshots rotate).

## Closure deps
`curl`, `tar`/`xz`, `gawk` (all via Arch `base`), `kitty`, plus `limine` +
`limine-mkinitcpio-hook` for the kernel boot entry — all already on the HyperWebster base.

## Install (root)
```
sudo sh ~/.local/share/hyperwebster/cachyos-repo-switch/install-cachyos-repo-switch.sh
```
Then reload caelestia (or log out/in) so the toggle loads.

## Use
- Settings → Services → **CachyOS repositories**: on opens a floating terminal showing
  the full pacman transaction (passwordless); off reverts to stock.
- Or terminal: `sudo hyperwebster-cachy-repo enable` / `disable`,
  `hyperwebster-cachy-repo status` / `detect` (add `--dry-run` to preview).

## Files
- `hyperwebster-cachy-repo`, `02-hyperwebster-cachy`, `install-cachyos-repo-switch.sh`,
  `CachyRepoToggleRow.qml`, `patch-servicespage.sh`.
