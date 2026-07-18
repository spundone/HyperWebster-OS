pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// HyperWebster: Settings → Additions — layer mod toggles + optional software.
// Prefers per-section `toggles` / `installs` from the status cache; falls back to
// filtering `items` by kind so a stale cache cannot turn toggles into install
// NavRows (which open a kitty popup and fail with kind=toggle).
PageBase {
    id: root

    title: qsTr("Additions")

    property var status: ({})
    readonly property var sections: status.sections || []

    property var hypr: ({
            windowRadius: 0,
            roundingScale: 0
        })

    function sectionToggles(section) {
        const t = section && section.toggles;
        if (t && t.length)
            return t;
        const items = (section && section.items) || [];
        return items.filter(i => (i.kind || "install") === "toggle");
    }

    function sectionInstalls(section) {
        const inst = section && section.installs;
        if (inst && inst.length)
            return inst;
        const items = (section && section.items) || [];
        return items.filter(i => (i.kind || "install") !== "toggle");
    }

    function applyRadius(key: string, value): void {
        Quickshell.execDetached(["hyperwebster-appearance", "set", key, String(value)]);
        appearanceProc.running = true;
    }

    function openFullAppearance(): void {
        // Wallpaper & style is Nexus page 0; Appearance is stack index 4.
        root.nState.currentPageIdx = 0;
        Qt.callLater(() => root.nState.openSubPage(4));
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

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

        Process {
            id: appearanceProc

            running: true
            command: ["hyperwebster-appearance", "status-json"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        root.hypr = Object.assign({}, root.hypr, JSON.parse(text));
                    } catch (e) {}
                }
            }
        }

        Process {
            id: checkProc

            // Always rewrite status (toggles/installs split) before re-read.
            command: ["sh", "-c", "\"$HOME/.local/bin/hyperwebster-additions\" status >/dev/null 2>&1"]
            running: true
            onExited: {
                readProc.running = true;
                appearanceProc.running = true;
            }
        }

        Process {
            id: installProc

            property string addId: ""

            command: ["kitty", "--class", "TUI.float", "-e", "sh", "-c", "\"$HOME/.local/bin/hyperwebster-additions\" install " + addId + "; printf '\\nPress Enter to close...'; read _"]
            onExited: readProc.running = true
        }

        Process {
            id: toggleProc

            property string addId: ""
            property bool turnOn: false

            command: ["sh", "-c", "\"$HOME/.local/bin/hyperwebster-additions\" " + (turnOn ? "enable " : "disable ") + addId]
            onExited: {
                checkProc.running = true;
            }
        }

        Repeater {
            model: root.sections

            delegate: ColumnLayout {
                id: sectionBlock

                required property var modelData
                required property int index

                readonly property var toggleItems: root.sectionToggles(modelData)
                readonly property var installItems: root.sectionInstalls(modelData)
                readonly property bool isAppearance: (modelData.id || "") === "appearance"

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    text: sectionBlock.modelData.label || ""
                }

                Repeater {
                    model: sectionBlock.toggleItems

                    ToggleRow {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        first: index === 0
                        // Keep the connected group open when radius steppers follow.
                        last: index === sectionBlock.toggleItems.length - 1 && !sectionBlock.isAppearance
                        text: modelData.name || ""
                        subtext: modelData.desc || ""
                        checked: modelData.enabled === true
                        onToggled: {
                            if (toggleProc.running)
                                return;
                            toggleProc.addId = modelData.id;
                            toggleProc.turnOn = checked;
                            toggleProc.running = true;
                        }
                    }
                }

                // Corner radius knobs under Appearance toggles (same place as Rounded corners).
                StepperRow {
                    visible: sectionBlock.isAppearance
                    Layout.fillWidth: true
                    label: qsTr("Shell corner scale")
                    subtext: qsTr("UI radii multiplier (0 = square)")
                    value: Math.round((root.hypr.roundingScale ?? GlobalConfig.appearance.rounding.scale) * 100)
                    from: 0
                    to: 200
                    stepSize: 5
                    onMoved: v => {
                        const s = v / 100;
                        GlobalConfig.appearance.rounding.scale = s;
                        if (s > 0)
                            Quickshell.execDetached(["hyperwebster-appearance", "ensure-rounding"]);
                        root.applyRadius("rounding-scale", s);
                    }
                }

                StepperRow {
                    visible: sectionBlock.isAppearance
                    Layout.fillWidth: true
                    label: qsTr("Window corner radius")
                    subtext: qsTr("Hyprland window rounding (px)")
                    value: root.hypr.windowRadius ?? 0
                    from: 0
                    to: 32
                    stepSize: 1
                    onMoved: v => {
                        root.hypr.windowRadius = v;
                        root.applyRadius("window-radius", v);
                    }
                }

                NavRow {
                    visible: sectionBlock.isAppearance
                    Layout.fillWidth: true
                    last: true
                    icon: "tune"
                    label: qsTr("More appearance…")
                    status: qsTr("Gaps, density, presets, glass")
                    onClicked: root.openFullAppearance()
                }

                Repeater {
                    model: sectionBlock.installItems

                    NavRow {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        first: index === 0
                        last: index === sectionBlock.installItems.length - 1
                        icon: modelData.icon || "extension"
                        label: modelData.name || ""
                        status: modelData.installed ? qsTr("Installed") : (modelData.desc || "")
                        onClicked: {
                            // Defensive: never open the install terminal for toggles.
                            if ((modelData.kind || "install") === "toggle") {
                                if (!toggleProc.running) {
                                    toggleProc.addId = modelData.id;
                                    toggleProc.turnOn = !(modelData.enabled === true);
                                    toggleProc.running = true;
                                }
                                return;
                            }
                            if (!modelData.installed && !installProc.running) {
                                installProc.addId = modelData.id;
                                installProc.running = true;
                            }
                        }
                    }
                }
            }
        }

        InfoRow {
            visible: root.sections.length === 0
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
            status: installProc.running ? qsTr("Install running in terminal…") : (toggleProc.running ? qsTr("Applying toggle…") : (checkProc.running ? qsTr("Checking…") : qsTr("Refreshes the list above")))
            onClicked: {
                if (!checkProc.running)
                    checkProc.running = true;
            }
        }
    }
}
