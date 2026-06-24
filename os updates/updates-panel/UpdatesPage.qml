pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// HyperWebster: the Updates settings page (replaces the upstream placeholder).
// Reads the JSON cache written by hyperwebster-update-check; "Update now" runs
// hyperwebster-update in a floating terminal (sudo + pacman prompts stay visible).
PageBase {
    id: root

    title: qsTr("Updates")

    property var status: ({})

    function count(v) {
        return v === undefined ? "…" : String(v);
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // The Process objects live INSIDE the layout (its `data` accepts
        // non-visual objects) — PageBase's default property is a single
        // `Item`, so declaring them at page level kills the whole shell
        // ("Cannot assign Process to QQuickItem*"). Same pattern as the
        // upstream AboutPage.

        // Read the cached status (instant; the user timer keeps it fresh).
        Process {
            id: readProc

            running: true
            command: ["sh", "-c", "cat \"${XDG_STATE_HOME:-$HOME/.local/state}/hyperwebster/update-status.json\" 2>/dev/null"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        root.status = JSON.parse(text);
                    } catch (e) {
                        root.status = {};
                    }
                }
            }
        }

        // Refresh the cache on demand.
        Process {
            id: checkProc

            command: ["sh", "-c", "\"$HOME/.local/bin/hyperwebster-update-check\" >/dev/null 2>&1"]
            onExited: readProc.running = true
        }

        // Run the real update in a visible floating terminal.
        Process {
            id: updateProc

            command: ["kitty", "--class", "TUI.float", "-e", "sh", "-c", "\"$HOME/.local/bin/hyperwebster-update\"; \"$HOME/.local/bin/hyperwebster-update-check\" >/dev/null 2>&1; printf '\\nPress Enter to close...'; read _"]
            onExited: readProc.running = true
        }

        SectionHeader {
            text: qsTr("Pending updates")
        }

        InfoRow {
            first: true
            label: qsTr("Official packages")
            value: root.count(root.status.repo)
        }

        InfoRow {
            label: qsTr("AUR packages")
            value: root.count(root.status.aur)
        }

        InfoRow {
            label: qsTr("Flatpak")
            value: root.count(root.status.flatpak)
        }

        InfoRow {
            last: true
            label: qsTr("HyperWebster layer")
            subtext: qsTr("Idempotent migrations applied by hyperwebster-update")
            value: root.status.migrations_pending === undefined ? "…" : (root.status.migrations_pending > 0 ? qsTr("%1 migration(s) pending").arg(root.status.migrations_pending) : qsTr("up to date"))
        }

        SectionHeader {
            text: qsTr("History")
        }

        InfoRow {
            first: true
            label: qsTr("Last full upgrade")
            value: root.status.last_upgrade || "—"
        }

        InfoRow {
            last: true
            label: qsTr("Last checked")
            value: root.status.checked ? root.status.checked.replace("T", " ").substring(0, 16) : "—"
        }

        SectionHeader {
            text: qsTr("Actions")
        }

        NavRow {
            first: true
            icon: "refresh"
            label: qsTr("Check for updates now")
            status: checkProc.running ? qsTr("Checking…") : qsTr("Refreshes the counts above")
            onClicked: {
                if (!checkProc.running)
                    checkProc.running = true;
            }
        }

        NavRow {
            last: true
            icon: "system_update_alt"
            label: qsTr("Update now")
            status: updateProc.running ? qsTr("Running in terminal…") : qsTr("Opens a terminal: snapshot, packages, HyperWebster layer")
            onClicked: {
                if (!updateProc.running)
                    updateProc.running = true;
            }
        }
    }
}
