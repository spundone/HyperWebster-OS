# update-prompts-fix - hyperwebster-update no longer "gets stuck" at yay menus

`hyperwebster-update` could appear to hang at yay's interactive menus.

## Symptom

Mid-`hyperwebster-update`, after the package list, the run appears to hang at:

```
==> Packages to exclude: (eg: "1 2 3", "1-3", "^4" or repo name)
 -> Excluding packages may cause partial upgrades and break systems
==>
```

This is yay's interactive **upgrade menu** waiting for input (Enter
continues), but a bare `==>` after a wall of output reads as a hang -
the user already answered the only prompt they expected
(`Update HyperWebster now? [y/N]`). Yay shows further menus when AUR packages
build (clean-build, diff), each another apparent stall.

## Fix

`patch-hyperwebster-update.sh` (idempotent, marker `answerupgrade`, backup at
`*.pre-menus-fix`, self-reverts if the regex misses) edits
`update_packages()` in the layer's `hyperwebster-update/bin/hyperwebster-update`:

```sh
local menus=""
[ "$HELPER" = yay ] && menus="--answerupgrade None --answerclean None --answerdiff None --answeredit None"
"$HELPER" -Syu $menus $nc
```

All four yay menus (upgrade-exclude, clean-build, diff, edit-PKGBUILD)
are pre-answered with `None`. Untouched: pacman's own
`Proceed with installation? [Y/n]` confirm (one meaningful confirmation
stays), `-y/--noconfirm` behaviour, and paru (no such menus).

For the builder this is a one-hunk edit to the layer source of
`hyperwebster-update` - fold it in directly; the patch script exists so the
migration can fix already-installed boxes.

## Test

1. `hyperwebster-update`, answer `y` → snapshot → package list → goes straight
   to pacman's `Proceed with installation? [Y/n]` (no `==>` exclude
   menu).
2. With an AUR upgrade pending (e.g. shelly-bin): no clean-build/diff
   menus during the build.
3. `hyperwebster-update -y` still fully non-interactive.

No new keybinds; nothing to add to `HyperWebster-keybindings.md`.

## Notes

The patch is idempotent and `bash -n` clean. Flags verified against yay v12.6.0
(`--answerupgrade` et al. present in `yay --help`).
