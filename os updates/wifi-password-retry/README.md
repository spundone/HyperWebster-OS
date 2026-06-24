# wifi-password-retry — recover from a wrong Wi-Fi password

Fixes a stock-Caelestia bug; worth upstreaming.

## Symptom

Enter a wrong Wi-Fi password once and you are locked out of that network
in the UI:

1. The password dialog saves the NetworkManager profile (with the bad
   PSK) immediately, and only deletes it if the dialog stays open long
   enough for its ~10-poll failure monitor to fire. Close the popout
   while it hangs on "Connecting…" — which is what everyone does — and
   the wrong-PSK profile survives.
2. Every later click on that network hits the saved-profile fast path in
   `utils/NetworkConnection.qml`, which activates the profile with a
   **null callback**: the auth failure is swallowed, the password dialog
   never reopens, and there is no forget-network control in the popout.
   Only `nmcli connection delete "<SSID>"` in a terminal gets you out.

## Cause

`/etc/xdg/quickshell/caelestia/utils/NetworkConnection.qml`,
`connectToNetwork()`:

```qml
if (hasSavedProfile) {
    Nmcli.connectToNetwork(network.ssid, "", network.bssid, null);   // <- trap
} else {
    // ... needsPassword -> password dialog (correct handling)
}
```

## Fix

`patch-network-connection.sh` (idempotent, marker
`hyperwebster wifi-password-retry`, backup at `*.pre-hyperwebster`) replaces the
null callback with one that, on `needsPassword`:

- stops the pending-connection timers (same cleanup the else-branch does),
- `Nmcli.forgetNetwork(ssid)` — drops the bad profile,
- reopens the password dialog (session path for the control center,
  `onPasswordNeeded` callback path for the bar popout).

Fixing this one spot also makes failure mode 1 self-healing: even if a
bad profile survives a closed dialog, the next click re-prompts instead
of looping silently. Profiles with a *correct* password are untouched —
their activation succeeds and the callback does nothing.

A pacman hook (`hyperwebster-wifi-password-retry.hook`) re-applies the patch
after every caelestia-shell upgrade, same mechanism as the updates-panel
patch.

## Version pin / drift

Pinned against the `NetworkConnection.qml` shipped with caelestia-shell
**2.0.2**. If upstream reshapes the `hasSavedProfile` branch, the patch
script detects the miss, warns, and leaves stock behaviour in place —
update the regex. If upstream fixes the bug properly, drop this
component and its hook.

## Test

1. Connect to a WPA network and deliberately enter a wrong password;
   close the popout while it says "Connecting…".
2. Click the same network again → the password dialog must reopen
   (stock behaviour: silent failure, no dialog, forever).
3. Enter the correct password → connects.
4. Relogin/reboot → still connected (saved profile now has the good PSK).

No new keybinds; nothing to add to `HyperWebster-keybindings.md`.
