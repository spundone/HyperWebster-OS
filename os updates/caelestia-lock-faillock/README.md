# caelestia-lock-faillock

## Symptom
User locked the screen; the Caelestia lock screen **would not accept the
correct password**. Only recovery was a hard **reboot**.

## Evidence (prior-boot journal, `journalctl --user -b -1`)
```
qs[…]:  PAM _pam_init_handlers: no default config other
qs[…]:  pam_unix(passwd:auth): authentication failure; … user=q     (×3)
qs[…]:  pam_faillock(passwd:auth): Consecutive login failures for user q account temporarily locked
```
(`qs` = Quickshell = the Caelestia shell hosting the lock.)

## Root cause (lock-out mechanism - high confidence)
- The lock authenticates via `PamContext { config: "passwd" }`
  (`modules/lock/Pam.qml:14`) → the **`passwd` PAM service**.
- On this build `/etc/pam.d/passwd` was extended to `auth include system-auth`,
  and **system-auth runs `pam_faillock`**.
- Failed unlocks are counted by faillock; past the threshold it **temporarily
  locks the account**, after which *every* attempt - including the correct
  password - is refused until the `/run/faillock` tally clears (reboot, or
  `faillock --reset`). That is exactly the reboot-to-recover the user hit.

## The initial failure trigger
Two possible causes of the first failures (before faillock engaged):
1. **Keyboard layout** on the lock surface (this install is **GB**; if the lock
   comes up US-layout, `@ " # £ \ | ~` mistype → auth fails).
2. **PAM stack init** (`no default config other`; module ordering under a
   uid-1000 Quickshell process).

## Fix
1. **Stop the lock from locking the account.** Ship a dedicated, **faillock-free**
   PAM service `/etc/pam.d/caelestia` (provided: `etc-pam.d-caelestia`;
   installed by `install-caelestia-lock-pam.sh`, root).
2. **Repoint the lock at it.** `modules/lock/Pam.qml`: `config: "passwd"` →
   `config: "caelestia"`.

A desktop lock must fail **closed-but-recoverable** (re-prompt), never lock the
account such that the correct password is refused.

## Builder integration (important)
`modules/lock/Pam.qml` lives under `/etc/xdg/quickshell/caelestia`, which is
re-applied by a pacman hook after every `caelestia-shell` upgrade. The `config:`
repoint must therefore be added to HyperWebster's **quickshell-patch + pacman-hook**
mechanism - the same one that re-applies the Updates page, Additions page, and
`NetworkConnection.qml` patches - as a 4th patched file. Do **not** hand-edit it
in place (a shell upgrade would revert it). Expected behaviour: lock → wrong
password ×5 (keeps re-prompting, account stays usable) → correct password
unlocks; the lock-surface layout is GB.

## Recovery for the user, no reboot
TTY (Ctrl+Alt+F2) login → `sudo faillock --user "$USER" --reset` → back to the
session (Ctrl+Alt+F1) and unlock. `Super+Alt+L` recovers a *hung* lock but does
**not** clear a faillock lock.

## Files
- `etc-pam.d-caelestia` - proposed faillock-free PAM service.
- `install-caelestia-lock-pam.sh` - idempotent installer (root).
- `migrations/1781431200-caelestia-lock-pam.sh` - delegates to it.
