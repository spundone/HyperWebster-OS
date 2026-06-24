# cachyos-repo-switch - CachyOS optimized repos + kernel (sudoless, auto-tier)

**Default on fresh HyperWebster installs** - `linux-cachyos` + CachyOS pacman repos are
bootstrapped at install time (offline-safe). The Settings toggle **reverts to stock**
or re-enables + runs userspace `-Suu` conversion.

Works **both directions** - OFF → reboot into stock `linux`; ON → reboot into
`linux-cachyos` + optimized userspace.

## What it is
One toggle in **Settings → Services** that switches the system **to/from**
CachyOS-optimized builds **and** the `linux-cachyos` kernel - passwordless,
auto-detecting the best x86-64 tier (v4 > v3), fully unattended (`--noconfirm`).
Refuses below x86-64-v3.

## Pieces
- **`hyperwebster-cachy-repo`** → `/usr/local/bin` - `detect` / `status` /
  `bootstrap` / `enable` / `disable` (+ `--dry-run`).
- **`02-hyperwebster-cachy`** → `/etc/sudoers.d` (0440, `visudo -c`-validated at install)
  - `%wheel` NOPASSWD, pinned to the four exact subcommands of the fixed helper.
- **`CachyRepoToggleRow.qml`** → `nexus/common/` - baked into the pinned
  hyperwebster-shell fork; this copy + `patch-servicespage.sh` are the migration
  path for old stock-caelestia installs.
- **`patch-servicespage.sh`** - inserts the toggle into `ServicesPage.qml` (only used
  by the hyperwebster-update migration; the builder skips it via HYPERWEBSTER_SKIP_SHELL_PATCH).

## Install-time bootstrap (OOB default)
The ISO builder vendors `cachyos-repo.tar.xz` + `linux-cachyos` into the offline
repo. The installer pacstraps the kernel, then runs `hyperwebster-cachy-repo bootstrap`
(offline - no `-Syu`, no userspace conversion). Once online, `enable` or the toggle
ON runs `pacman -Suu` to swap userspace packages to CachyOS optimized builds.

## Two design fixes baked in - DO NOT reintroduce the bugs
1. **Architecture (critical).** CachyOS v3/v4 packages have arch `x86_64_v3`/`x86_64_v4`.
   Upstream relies on its OWN pacman (reads `Architecture = auto` as "include v3/v4").
   We keep **stock pacman** (reads `auto` as just `x86_64`) → it would arch-reject every
   v3/v4 package and the conversion would silently do nothing. So `enable` sets
   `Architecture` EXPLICITLY to the tier (`x86_64 x86_64_v3 x86_64_v4` for v4,
   `x86_64 x86_64_v3` for v3); `disable` restores `Architecture = auto`.
2. **Targeted revert (no whole-base pull).** `disable` reinstalls ONLY packages whose
   local-DB `Packager` is `CachyOS …` (excluding the cachy keyring/mirrorlist pkgs,
   removed separately) - never the full base. Nothing converted ⇒ nothing to do.

## Why stock pacman (and `--ignore pacman`)
Upstream `cachyos-repo.sh` swaps in a CachyOS `pacman`. We reuse its signed
keyring/mirrorlists + `.awk` stanza files but drive stock pacman ourselves.
`enable` runs `pacman -Suu --ignore pacman` and pins pacman via `IgnorePkg`.

## Kernel guard
`enable` installs `linux-cachyos` + `-headers` (limine-mkinitcpio-hook generates
boot entries; stock `linux` stays as a fallback). `disable` removes the cachy kernel
ONLY after confirming stock `linux` is installed. **Reboot** after ON/OFF to switch
the running kernel; pick the entry at the Limine menu.

## Offline ISO bundle
`hyperwebster.sh` downloads `linux-cachyos`, headers, and keyring/mirrorlist packages
from the CachyOS mirror at ISO build time and vendors `cachyos-repo.tar.xz` on the
install media. Fresh installs need **no network** for the kernel; userspace conversion
needs network (toggle ON or `enable`).

## CachyOS-exclusive packages don't revert (by design)
Any package with no stock equivalent stays a CachyOS build on OFF and is reported, not
removed. The `linux-cachyos` kernel is the exception (removed explicitly, guarded).

## Closure deps
`curl`, `tar`/`xz`, `gawk` (all via Arch `base`), `kitty`, plus `limine` +
`limine-mkinitcpio-hook` for the kernel boot entry - all already on the HyperWebster base.

## Install (root)
```
sudo sh ~/.local/share/hyperwebster/cachyos-repo-switch/install-cachyos-repo-switch.sh
```
Then reload caelestia (or log out/in) so the toggle loads.

## Use
- Settings → Services → **CachyOS kernel & repos**: off reverts to stock; on re-enables
  + converts userspace (floating terminal shows the pacman transaction).
- Or terminal: `sudo hyperwebster-cachy-repo enable` / `disable`,
  `hyperwebster-cachy-repo status` / `detect` (add `--dry-run` to preview).

## Files
- `hyperwebster-cachy-repo`, `02-hyperwebster-cachy`, `install-cachyos-repo-switch.sh`,
  `CachyRepoToggleRow.qml`, `patch-servicespage.sh`.
