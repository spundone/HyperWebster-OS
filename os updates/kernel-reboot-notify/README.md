# kernel-reboot-notify

## Symptom / gap
When `hyperwebster-update` (or any `pacman -Syu`/`yay`) installs a **new kernel**,
nothing tells the user to reboot. The new kernel + modules are written to disk,
but the **old kernel keeps running** - and its `/usr/lib/modules/<running>` dir
has been replaced, so the live session can no longer load matching modules
(USB, filesystems, etc. can fail to load on demand). On HyperWebster this also means
the freshly-built UKI isn't booted yet. The user only finds out when something
breaks - or, with **F4**, when they reboot and the default entry drops to a TTY.

## Fix
1. **`hyperwebster-reboot-check`** (→ `~/.local/bin`): if the running kernel's
   modules dir is gone (the update replaced it), it writes a stamp
   (`$XDG_STATE_HOME/hyperwebster/reboot-required`), prints a yellow banner, and
   raises a **critical desktop notification** ("Kernel updated - reboot to load
   it (X → Y)"). It clears the stamp once the running kernel matches disk again.
2. **`95-hyperwebster-kernel-reboot.hook`** (→ `/etc/pacman.d/hooks`): a PostTransaction
   Path hook on `usr/lib/modules/*/vmlinuz` that prints a reboot reminder in the
   pacman/yay output - so updates done outside `hyperwebster-update` warn too.
3. **`hyperwebster-update` wiring**: calls `hyperwebster-reboot-check` as its last step,
   so an interactive update ends with the reminder + notification.

The installer (`install-kernel-reboot-notify.sh`) does all three idempotently.
The pacman-hook step needs root.

### Optional (builder): re-warn at login until rebooted
Add `hyperwebster-reboot-check` to an `exec-once` (e.g. alongside `hyperwebster-welcome`
in `hypr-user.conf`) so a pending reboot is re-surfaced each login while the
stamp exists. Not included by default to avoid touching `hypr-user.conf` here.

## Builder integration
Ship `hyperwebster-reboot-check` in the layer's bin, ship the pacman hook in the
ISO, and add the one-line call to the canonical `hyperwebster-update` (the installer
shows the exact insertion). Pairs with **F4**: until F4 is fixed the reboot
notice tells the user to pick the UKI entry.

## Verify
```
# simulate (don't actually remove modules): the helper keys off
# /usr/lib/modules/$(uname -r) - present now, so it's a no-op:
hyperwebster-reboot-check; echo "exit=$?"
# after a real kernel update it prints the banner + notifies and stamps
# ~/.local/state/hyperwebster/reboot-required
```

## Files
- `hyperwebster-reboot-check` - detector + notifier.
- `95-hyperwebster-kernel-reboot.hook` - pacman PostTransaction reminder.
- `install-kernel-reboot-notify.sh` - idempotent installer (hook step needs root).
- `migrations/1781438400-kernel-reboot-notify.sh` - delegates to it.
