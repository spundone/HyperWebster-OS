#!/bin/sh
# patch-network-connection.sh — fix the Wi-Fi saved-profile password trap.
# Runs as root (via sudo from the installer, or via the pacman hook after
# every caelestia-shell upgrade, which reverts NetworkConnection.qml).
# Idempotent.
#
# Symptom: enter a wrong Wi-Fi password once and the shell saves the NM
# profile with the bad PSK; every later click on that network silently
# reuses it and the password dialog never reopens.
#
# Cause: in utils/NetworkConnection.qml connectToNetwork(), the
# hasSavedProfile branch calls Nmcli.connectToNetwork(..., null) — a null
# callback and no password-dialog path, so an auth failure is swallowed.
#
# Fix: pass a real callback; when the activation comes back needsPassword,
# forget the (bad) saved profile and reopen the password dialog — same
# cleanup + dialog logic the no-saved-profile branch already uses.
#
# TARGET is overridable for testing the regex against a copy.
set -eu

TARGET=${TARGET:-/etc/xdg/quickshell/caelestia/utils/NetworkConnection.qml}

[ -f "$TARGET" ] || { echo "caelestia-shell not found at $TARGET — nothing to patch"; exit 0; }

if grep -q 'hyperwebster wifi-password-retry' "$TARGET"; then
  echo ":: NetworkConnection.qml already patched"
  exit 0
fi

cp -n "$TARGET" "$TARGET.pre-hyperwebster"

perl -0pi -e 's/if \(hasSavedProfile\) \{\s*\n\s*Nmcli\.connectToNetwork\(network\.ssid, "", network\.bssid, null\);\s*\n(\s*)\} else \{/if (hasSavedProfile) {\n                \/\/ >>> hyperwebster wifi-password-retry >>>\n                \/\/ A saved profile can hold a wrong password. Stock code passed\n                \/\/ a null callback here, so a failed activation never re-prompted.\n                \/\/ On auth failure: forget the bad profile and reopen the dialog.\n                Nmcli.connectToNetwork(network.ssid, "", network.bssid, result => {\n                    if (result \&\& result.needsPassword) {\n                        if (Nmcli.pendingConnection) {\n                            Nmcli.connectionCheckTimer.stop();\n                            Nmcli.immediateCheckTimer.stop();\n                            Nmcli.immediateCheckTimer.checkCount = 0;\n                            Nmcli.pendingConnection = null;\n                        }\n                        Nmcli.forgetNetwork(network.ssid);\n                        if (session \&\& session.network) {\n                            session.network.showPasswordDialog = true;\n                            session.network.pendingNetwork = network;\n                        } else if (onPasswordNeeded) {\n                            onPasswordNeeded(network);\n                        }\n                    }\n                });\n                \/\/ <<< hyperwebster wifi-password-retry <<<\n$1} else {/' "$TARGET"

if grep -q 'hyperwebster wifi-password-retry' "$TARGET"; then
  echo ":: patched $TARGET (Wi-Fi wrong-password recovery)"
else
  echo "WARNING: patch did not apply — upstream NetworkConnection.qml changed shape." >&2
  echo "         Stock behaviour kept (wrong saved password still cannot be changed" >&2
  echo "         from the UI); update the regex in $(basename "$0") for the new" >&2
  echo "         caelestia-shell version." >&2
fi
