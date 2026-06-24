pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus
import qs.modules.bar.popouts as BarPopouts

StyledRect {
    id: root

    required property DrawerVisibilities visibilities
    required property BarPopouts.Wrapper popouts

    // HyperWebster: the gamepad "Game Mode" toggle launches DeckShift gaming. Hide it
    // entirely when DeckShift isn't installed (no gamescope session file) — checked
    // once at load by deckshiftProbe below.
    property bool deckshiftInstalled: false

    Process {
        id: deckshiftProbe
        running: true
        command: ["test", "-f", "/usr/share/wayland-sessions/gamescope-session-steam-nm.desktop"]
        onExited: (exitCode, exitStatus) => root.deckshiftInstalled = exitCode === 0
    }

    readonly property var quickToggles: {
        const seenIds = new Set();

        return Config.utilities.quickToggles.filter(item => {
            if (!(item.enabled ?? true))
                return false;

            if (seenIds.has(item.id)) {
                return false;
            }

            if (item.id === "vpn") {
                return GlobalConfig.utilities.vpn.provider.some(p => typeof p === "object" ? (p.enabled === true) : false);
            }

            // HyperWebster: drop the Game Mode tile unless DeckShift is installed.
            if (item.id === "gameMode") {
                return root.deckshiftInstalled;
            }

            seenIds.add(item.id);
            return true;
        });
    }
    readonly property int splitIndex: Math.ceil(quickToggles.length / 2)
    readonly property bool needExtraRow: quickToggles.length > 6

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        StyledText {
            text: qsTr("Quick Toggles")
            font: Tokens.font.body.medium
        }

        QuickToggleRow {
            model: root.needExtraRow ? root.quickToggles.slice(0, root.splitIndex) : root.quickToggles
        }

        QuickToggleRow {
            visible: root.needExtraRow
            model: root.needExtraRow ? root.quickToggles.slice(root.splitIndex) : []
        }
    }

    component QuickToggleRow: ButtonRow {
        property alias model: repeater.model

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        Repeater {
            id: repeater

            delegate: DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "wifi"
                    delegate: Toggle {
                        icon: "wifi"
                        checked: Nmcli.wifiEnabled
                        onClicked: Nmcli.toggleWifi()
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: Toggle {
                        icon: "bluetooth"
                        checked: Bluetooth.defaultAdapter?.enabled ?? false // qmllint disable unresolved-type
                        onClicked: {
                            const adapter = Bluetooth.defaultAdapter; // qmllint disable unresolved-type
                            if (adapter)
                                adapter.enabled = !adapter.enabled;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "mic"
                    delegate: Toggle {
                        icon: "mic"
                        checked: !Audio.sourceMuted
                        onClicked: {
                            const audio = Audio.source?.audio;
                            if (audio)
                                audio.muted = !audio.muted;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "settings"
                    delegate: Toggle {
                        icon: "settings"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        isToggle: false
                        onClicked: {
                            root.visibilities.utilities = false;
                            WindowFactory.create();
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "gameMode"
                    delegate: Toggle {
                        id: gmTog
                        // HyperWebster: launch the DeckShift gaming session if installed;
                        // otherwise do nothing. (Was caelestia's cosmetic Game Mode.)
                        // Kept styled as an off-toggle (muted, outline icon) — the
                        // gamepad is a momentary LAUNCHER, not a stateful toggle.
                        // DEBOUNCED: a fast double-click must not fire two
                        // `switch-to-gaming` runs — two SDDM restarts race the
                        // one-shot autologin and drop you at the password greeter.
                        // Guard mirrors the Super+Shift+S bind + the deckshift-login
                        // install-check, so it no-ops if DeckShift is absent.
                        property bool launching: false
                        icon: "gamepad"
                        disabled: launching
                        onClicked: {
                            if (gmTog.launching)
                                return;
                            gmTog.launching = true;
                            gmTog.internalChecked = false; // don't latch "on"
                            relockTimer.start();
                            Quickshell.execDetached(["sh", "-c", "[ -x /usr/local/bin/switch-to-gaming ] && [ -f /usr/share/wayland-sessions/gamescope-session-steam-nm.desktop ] && exec /usr/local/bin/switch-to-gaming"]);
                        }

                        Timer {
                            id: relockTimer
                            interval: 5000
                            onTriggered: gmTog.launching = false
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "dnd"
                    delegate: Toggle {
                        icon: "notifications_off"
                        checked: Notifs.dnd
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                }
                DelegateChoice {
                    roleValue: "vpn"
                    delegate: Toggle {
                        icon: "vpn_key"
                        checked: VPN.connected && VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        enabled: !VPN.connecting
                        isToggle: VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        onClicked: VPN.toggle()
                    }
                }
            }
        }
    }

    component Toggle: IconButton {
        inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        fillWidth: true
        isToggle: true
        isRound: true
        shapeMorph: true
    }
}
