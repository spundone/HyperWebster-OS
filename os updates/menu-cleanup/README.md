# menu-cleanup - hide uuctl from the launcher

## Symptom

`uuctl` appears in the Super+Space launcher. It is uwsm's user-systemd-
unit manager - a dmenu-driven admin utility that ships a desktop entry
with the `uwsm` package. Not an app a user should be offered; the
change "system-polish" hide list (avahi/foot/qv4l2/pinentry…) simply
missed it because it was specified before uwsm's entry was noticed.

## Fix

Same mechanism as system-polish A1: a user-level
`~/.local/share/applications/uuctl.desktop` override with
`NoDisplay=true` + `Hidden=true` shadows the system entry. Idempotent,
no sudo.

## Packaging

Fold `uuctl` into the `HIDDEN` list in
`system-polish/install-system-polish.sh` (one word) - this component
then only matters as a migration for boxes installed from older ISOs.

## Considered and left visible (builder judgment calls)

- `vim.desktop` - console Vim alongside Neovim; harmless, some users
  want it.
- `limine-snapper-restore.desktop` - GUI snapshot restore; arguably a
  recovery feature worth keeping discoverable.
- `cups.desktop` ("Manage Printing") + `system-config-printer.desktop`
  ("Print Settings") - mild duplication, both functional.

## Test

`Super+Space` → type "uuctl" → no result. (Entries for the items above
still present.)
