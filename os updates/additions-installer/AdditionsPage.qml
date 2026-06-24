pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// HyperWebster: the Additions settings page (replaces the upstream Plugins
// placeholder). Optional software installed on demand from official sources
// (pacman repos / upstream installers — no AUR, no Flatpak). Items come from
// the additions.json manifest via the status cache written by
// hyperwebster-additions; Install runs in a visible floating terminal so
// git/sudo/pacman output and prompts stay in front of the user.
PageBase {
    id: root

    title: qsTr("Additions")

    property var status: ({})
    readonly property var items: status.items || []

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // The Process objects live INSIDE the layout (its `data` accepts
        // non-visual objects) — PageBase's default property is a single
        // `Item`, so declaring them at page level kills the whole shell.
        // Same pattern as UpdatesPage / the upstream AboutPage.

        // Read the cached status (instant).
        Process {
            id: readProc

            running: true
            command: ["sh", "-c", "cat \"${XDG_STATE_HOME:-$HOME/.local/state}/hyperwebster/additions-status.json\" 2>/dev/null"]
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

        // Refresh the cache on demand (re-runs every item's check).
        Process {
            id: checkProc

            command: ["sh", "-c", "\"$HOME/.local/bin/hyperwebster-additions\" status >/dev/null 2>&1"]
            onExited: readProc.running = true
        }

        // Run an installer in a visible floating terminal.
        Process {
            id: installProc

            property string addId: ""

            command: ["kitty", "--class", "TUI.float", "-e", "sh", "-c", "\"$HOME/.local/bin/hyperwebster-additions\" install " + addId + "; printf '\\nPress Enter to close...'; read _"]
            onExited: readProc.running = true
        }

        SectionHeader {
            text: qsTr("Optional software")
        }

        Repeater {
            model: root.items

            NavRow {
                required property var modelData
                required property int index

                first: index === 0
                last: index === root.items.length - 1
                icon: modelData.icon || "extension"
                label: modelData.name
                status: modelData.installed ? qsTr("Installed") : modelData.desc
                onClicked: {
                    if (!modelData.installed && !installProc.running) {
                        installProc.addId = modelData.id;
                        installProc.running = true;
                    }
                }
            }
        }

        InfoRow {
            visible: root.items.length === 0
            first: true
            last: true
            label: qsTr("No additions manifest")
            value: "—"
        }

        SectionHeader {
            text: qsTr("Actions")
        }

        NavRow {
            first: true
            last: true
            icon: "refresh"
            label: qsTr("Re-check installed state")
            status: installProc.running ? qsTr("Install running in terminal…") : (checkProc.running ? qsTr("Checking…") : qsTr("Refreshes the list above"))
            onClicked: {
                if (!checkProc.running)
                    checkProc.running = true;
            }
        }
    }
}
