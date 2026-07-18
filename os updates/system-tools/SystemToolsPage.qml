pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.components.filedialog
import qs.services
import qs.utils
import qs.modules.nexus
import qs.modules.nexus.common

// HyperWebster: Settings → System tools — account photo + hardware / kernel apps.
PageBase {
    id: root

    title: qsTr("System tools")

    readonly property string facePath: `${Paths.home}/.face`
    readonly property string logoPath: Quickshell.shellDir + "/assets/hyperwebster-logo.png"
    property bool faceReady: false
    property int faceEpoch: 0
    readonly property string avatarSource: (faceReady ? `file://${facePath}` : logoPath) + "?t=" + faceEpoch

    function refreshFace(): void {
        faceEpoch++
    }

    function openTui(argv): void {
        const cmd = ["kitty", "--class", "TUI.float", "-e"].concat(argv)
        Quickshell.execDetached(cmd)
    }

    function openGui(bin): void {
        Quickshell.execDetached(["sh", "-c", "command -v \"$1\" >/dev/null && exec \"$1\" || notify-send -u critical 'System tools' \"$1 is not installed\"", "sh", bin])
    }

    FileDialog {
        id: facePicker

        title: qsTr("Select a profile picture")
        filterLabel: qsTr("Image files")
        filters: Images.validImageExtensions
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`))) {
                root.faceReady = true
                root.refreshFace()
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, qsTr("Profile picture changed"), qsTr("Lock screen and dashboard will use this photo.")])
            } else {
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", qsTr("Unable to change profile picture"), qsTr("Copy to ~/.face failed.")])
            }
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        FileView {
            path: root.facePath
            watchChanges: true
            onFileChanged: {
                reload()
                root.refreshFace()
            }
            onLoaded: {
                root.faceReady = true
                root.refreshFace()
            }
            onLoadFailed: root.faceReady = false
        }

        SectionHeader {
            text: qsTr("Account")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: accountCol.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: accountCol

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                spacing: Tokens.spacing.medium

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 88
                    implicitHeight: 88

                    Rectangle {
                        id: previewMask

                        anchors.centerIn: parent
                        width: 80
                        height: 80
                        radius: 40
                        visible: false
                        layer.enabled: true
                    }

                    Item {
                        anchors.centerIn: parent
                        width: 80
                        height: 80
                        layer.enabled: true
                        layer.effect: Mask {
                            maskSource: previewMask
                        }

                        Image {
                            anchors.fill: parent
                            source: root.avatarSource
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 80
                        height: 80
                        radius: 40
                        color: "transparent"
                        border.width: 1
                        border.color: Colours.palette.m3outlineVariant
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: SysInfo.user || qsTr("user")
                    font: Tokens.font.title.medium
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("Shown on the lock screen and dashboard. Photos are cropped to a circle.")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }
            }
        }

        NavRow {
            first: true
            icon: "image"
            label: qsTr("Change profile photo")
            status: qsTr("Saved to ~/.face")
            onClicked: facePicker.open()
        }

        NavRow {
            last: true
            icon: "refresh"
            label: qsTr("Reset to Starman mark")
            status: faceReady ? qsTr("Removes custom photo") : qsTr("Already using Starman")
            onClicked: {
                Quickshell.execDetached(["rm", "-f", root.facePath])
                root.faceReady = false
                root.refreshFace()
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", qsTr("Profile picture reset"), qsTr("Lock screen will show the Starman mark.")])
            }
        }

        SectionHeader {
            text: qsTr("Display & input")
        }

        NavRow {
            first: true
            icon: "monitor"
            label: qsTr("Display")
            status: qsTr("hyprmoncfg · Super+Ctrl+H")
            onClicked: root.openTui([
                "hyprmoncfg",
                "--hypr-config", `${Paths.home}/.config/caelestia/hypr-user.conf`,
                "--monitors-conf", `${Paths.home}/.config/hypr/monitors.conf`
            ])
        }

        NavRow {
            icon: "keyboard"
            label: qsTr("Keyboard & mouse")
            status: qsTr("keyd remap · Super+Ctrl+I")
            onClicked: root.openTui(["hyperwebster-input-remap"])
        }

        NavRow {
            icon: "volume_up"
            label: qsTr("Sound settings")
            status: qsTr("pavucontrol")
            onClicked: root.openGui("pavucontrol")
        }

        NavRow {
            last: true
            icon: "bluetooth"
            label: qsTr("Bluetooth")
            status: qsTr("Open Connected devices")
            onClicked: {
                const pages = PageRegistry.pages
                for (let i = 0; i < pages.length; i++) {
                    if (pages[i].icon === "devices_other") {
                        root.nState.currentPageIdx = i
                        return
                    }
                }
                root.openGui("blueman-manager")
            }
        }

        SectionHeader {
            text: qsTr("System")
        }

        NavRow {
            first: true
            icon: "memory"
            label: qsTr("CachyOS kernel manager")
            status: qsTr("Install / switch kernels")
            onClicked: root.openGui("cachyos-kernel-manager")
        }

        NavRow {
            icon: "terminal"
            label: qsTr("System monitor")
            status: qsTr("btop")
            onClicked: root.openTui(["btop"])
        }

        NavRow {
            icon: "history"
            label: qsTr("Btrfs snapshots")
            status: qsTr("hyperwebster-snapshots")
            onClicked: root.openTui(["hyperwebster-snapshots"])
        }

        NavRow {
            last: true
            icon: "build"
            label: qsTr("Maintenance menu")
            status: qsTr("Super+Ctrl+Shift+M")
            onClicked: Quickshell.execDetached(["hyperwebster-maint"])
        }
    }
}
