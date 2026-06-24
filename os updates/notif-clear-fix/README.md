# notif-clear-fix - notifications popout "Clear" button did nothing

The fix lives in the `hyperwebster-shell` fork (package-owned file), so the
canonical fix is a one-handler change in the fork source; this folder also
ships a fallback patch for already-installed boxes.

## Symptom
In the Notifications popout (off the bell), clicking **Clear** does nothing - the
notification cards stay. Per-notification state is untouched; the count stays.

## Root cause
`modules/nsbar/panels/NsNotifications.qml` Clear handler was:

```qml
onClicked: {
    for (const n of Notifs.notClosed)
        n.notification?.dismiss();
}
```

`n` is a `NotifData` wrapper. Clearing a notification is `NotifData.close()`
(`services/NotifData.qml`):

```qml
function close(): void {
    closed = true;                                   // drops it from notClosed → card disappears
    if (locks.size === 0 && Notifs.list.includes(this)) {
        Notifs.list = Notifs.list.filter(n => n !== this);
        notification?.dismiss();                     // dismiss the server obj (if any)
        destroy();
    }
}
```

The button skipped all of that and called only `notification?.dismiss()`:
- it never set `closed` or removed the item from `Notifs.list`, so `notClosed`
  (the popout's model) was unchanged → **cards never disappear**; and
- for notifications restored from disk (`services/Notifs.qml` `storage`/FileView),
  `notification` is null, so `?.dismiss()` is a complete **no-op**.

The service already does it correctly in two places - the `clearNotifs`
`CustomShortcut` and the `notifs` IPC `clear()` both do
`for (const notif of root.list.slice()) notif.close();`. The button just didn't
match.

## Fix
Make the Clear handler mirror the service:

```qml
onClicked: {
    for (const n of Notifs.list.slice())   // slice() copy → safe to mutate mid-loop
        n.close();
}
```

Corrected file: `NsNotifications.qml` (drop-in for
`modules/nsbar/panels/NsNotifications.qml`).

## Integration
- **Builder (canonical):** replace `modules/nsbar/panels/NsNotifications.qml` in
  the **hyperwebster-shell fork** with the one here; rebuild the package. Set
  `HYPERWEBSTER_SKIP_SHELL_PATCH` for the build so the fallback patch below is skipped.
- **Already-installed boxes (stopgap):** `install-notif-clear-fix.sh` backs up and
  overwrites the package-owned file. It is reverted by the next `hyperwebster-shell`
  upgrade - which is fine, because that upgrade carries the fixed file once the
  fork is patched. Migration: `1781470800-notif-clear-fix.sh` (delegates via
  `$HYPERWEBSTER_SRC`).
  **Shell restart required:** the shell runs as `qs -c caelestia -n -d` and `-n`
  disables the file watcher, so the patched file is NOT hot-reloaded - the user
  must restart the shell (**Ctrl+Super+Alt+R**, i.e.
  `qs -c caelestia kill; sleep .1; caelestia shell -d`) or log out/in for the new
  Clear handler to load. The installer prints this reminder.

## Apply on this box now (needs root; sudo was password-prompted this session)
```sh
sudo sh ~/hyperwebster-handoff/notif-clear-fix/install-notif-clear-fix.sh
```
Then reload the shell (log out/in, or restart the caelestia shell). Quickshell
usually hot-reloads on file change, so Clear may start working immediately.

## Files
- `NsNotifications.qml`, `install-notif-clear-fix.sh`, `1781470800-notif-clear-fix.sh`.
