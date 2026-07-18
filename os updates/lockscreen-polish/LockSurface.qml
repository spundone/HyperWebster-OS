pragma ComponentBehavior: Bound

// HyperWebster lock surface — frosted wallpaper, ambient motion, Starman mark.
// Still feeds PAM via pam.handleKey (never compares secrets in QML).

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    readonly property bool errored: root.pam.state === "error" || root.pam.state === "fail"
    readonly property string wallSource: Wallpapers.current || Quickshell.shellPath("assets/wallpaper.webp")
    readonly property string logoSource: Quickshell.shellPath("assets/hyperwebster-logo.png")
    readonly property string facePath: `${Paths.home}/.face`
    // Prefer ~/.face (Settings / dashboard picker); fall back to Starman mark.
    property bool faceReady: false
    readonly property string avatarSource: faceReady ? `file://${root.facePath}` : root.logoSource

    contentItem.Config.screen: screen?.name ?? ""
    contentItem.Tokens.screen: screen?.name ?? ""

    color: "#080a0e"

    Connections {
        function onUnlock(): void {
            root.lock.locked = false;
        }

        target: root.lock
    }

    // ── Live-feeling wallpaper (ken burns) + heavy blur ───────────────────
    Item {
        id: wallHost

        anchors.fill: parent
        clip: true

        // Fallback screencopy (if wallpaper path empty / fails)
        ScreencopyView {
            id: screenBg

            anchors.fill: parent
            captureSource: root.screen
            visible: wallImg.status !== Image.Ready
            z: 0
        }

        Image {
            id: wallImg

            anchors.centerIn: parent
            width: parent.width * 1.12
            height: parent.height * 1.12
            source: root.wallSource
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            z: 1

            SequentialAnimation on scale {
                running: wallImg.status === Image.Ready
                loops: Animation.Infinite
                NumberAnimation {
                    from: 1.0
                    to: 1.08
                    duration: 28000
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    from: 1.08
                    to: 1.0
                    duration: 28000
                    easing.type: Easing.InOutSine
                }
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 96
            blurMultiplier: 1.15
            brightness: -0.18
            saturation: 0.18
            contrast: 0.05
        }
    }

    // Soft vignette / scrim (lighter than stock so blur shows through)
    Rectangle {
        anchors.fill: parent
        z: 2
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.rgba(4 / 255, 6 / 255, 10 / 255, 0.35)
            }
            GradientStop {
                position: 0.45
                color: Qt.rgba(8 / 255, 10 / 255, 14 / 255, 0.25)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(4 / 255, 6 / 255, 10 / 255, 0.55)
            }
        }
    }

    // Ambient orbs — screensaver-lite motion without video
    Repeater {
        model: 3

        Rectangle {
            required property int index

            width: 280 + index * 90
            height: width
            radius: width / 2
            z: 3
            opacity: 0.14 - index * 0.03
            color: index === 0 ? Colours.palette.m3primary : (index === 1 ? Colours.palette.m3tertiary : Colours.palette.m3secondary)

            x: root.width * (0.15 + index * 0.28) - width / 2
            y: root.height * (0.25 + index * 0.18) - height / 2

            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation {
                    to: root.width * (0.25 + index * 0.2)
                    duration: 16000 + index * 4000
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: root.width * (0.1 + index * 0.25)
                    duration: 16000 + index * 4000
                    easing.type: Easing.InOutSine
                }
            }

            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation {
                    to: root.height * (0.35 + index * 0.12)
                    duration: 18000 + index * 3500
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: root.height * (0.2 + index * 0.15)
                    duration: 18000 + index * 3500
                    easing.type: Easing.InOutSine
                }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1
                blurMax: 64
            }
        }
    }

    // Keyboard capture
    Item {
        anchors.fill: parent
        z: 10
        focus: true
        Component.onCompleted: forceActiveFocus()
        Keys.onPressed: event => root.pam.handleKey(event)
    }

    // Top status
    RowLayout {
        z: 11
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 22
        anchors.leftMargin: 28
        anchors.rightMargin: 28

        RowLayout {
            spacing: 8
            NsIcon {
                icon: "lock"
                color: Theme.textMuted
                size: 15
            }
            StyledText {
                text: qsTr("HyperWebster · Locked")
                color: Theme.textMuted
                font.family: Theme.font.family
                font.pixelSize: Theme.font.bar
            }
        }

        Item {
            Layout.fillWidth: true
        }

        RowLayout {
            spacing: 14
            NsIcon {
                icon: Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
                color: Theme.textMuted
                size: 15
            }
            NsIcon {
                icon: Bluetooth.defaultAdapter?.enabled ? "bluetooth_connected" : "bluetooth_disabled"
                color: Theme.textMuted
                size: 15
            }
            RowLayout {
                spacing: 6
                visible: UPower.displayDevice.isLaptopBattery
                NsIcon {
                    icon: Icons.getBatteryIcon(UPower.displayDevice.percentage, [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged].includes(UPower.displayDevice.state))
                    color: Theme.textMuted
                    size: 15
                }
                StyledText {
                    text: Math.round(UPower.displayDevice.percentage * 100) + "%"
                    color: Theme.textMuted
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.bar
                }
            }
        }
    }

    // Centre
    ColumnLayout {
        z: 11
        anchors.centerIn: parent
        spacing: 0

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.format("hh:mm")
            color: Theme.text
            font.family: Theme.font.family
            font.pixelSize: 108
            font.weight: Font.ExtraLight
            font.letterSpacing: 3
            style: Text.Raised
            styleColor: Qt.rgba(0, 0, 0, 0.35)
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.format("ddd, d MMMM yyyy")
            color: Theme.textMuted
            font.family: Theme.font.family
            font.pixelSize: 15
        }

        // Profile photo / Starman — always circular-clipped (never a square in a ring)
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 56
            implicitWidth: 86
            implicitHeight: 86

            FileView {
                path: root.facePath
                watchChanges: true
                onFileChanged: reload()
                onLoaded: root.faceReady = true
                onLoadFailed: root.faceReady = false
            }

            Rectangle {
                anchors.centerIn: parent
                width: 86
                height: 86
                radius: 43
                color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.18)

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 0.6
                    shadowOpacity: 0.45
                    shadowColor: Qt.rgba(0, 0, 0, 0.7)
                    shadowVerticalOffset: 8
                }
            }

            // Invisible circle used as the opacity mask for the avatar.
            Rectangle {
                id: avatarMask

                anchors.centerIn: parent
                width: 72
                height: 72
                radius: 36
                visible: false
                layer.enabled: true
            }

            Item {
                id: avatarClip

                anchors.centerIn: parent
                width: 72
                height: 72
                layer.enabled: true
                layer.effect: Mask {
                    maskSource: avatarMask
                }

                Image {
                    id: logo

                    anchors.fill: parent
                    source: root.avatarSource
                    // Crop fills the circle; Fit left letterboxed squares inside the ring.
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    visible: status === Image.Ready
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 72
                height: 72
                radius: 36
                visible: logo.status !== Image.Ready
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop {
                        position: 0
                        color: Colours.palette.m3primary
                    }
                    GradientStop {
                        position: 1
                        color: Colours.palette.m3tertiary
                    }
                }
                NsIcon {
                    anchors.centerIn: parent
                    icon: "person"
                    color: Colours.on(Colours.palette.m3primary)
                    size: 32
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 14
            text: SysInfo.user || "user"
            color: Theme.text
            font.family: Theme.font.family
            font.pixelSize: 14
        }

        // Frosted password glass
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 18
            implicitWidth: 340
            implicitHeight: 48
            radius: 16
            color: Colours.transparency.enabled ? Colours.layer(Colours.palette.m3surfaceContainer, 2) : Qt.rgba(17 / 255, 20 / 255, 26 / 255, 0.55)
            border.width: 1
            border.color: root.errored ? Qt.rgba(224 / 255, 116 / 255, 106 / 255, 0.65) : Qt.rgba(1, 1, 1, 0.16)

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 0.8
                shadowOpacity: 0.35
                shadowColor: "#000000"
                shadowVerticalOffset: 10
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 14
                spacing: 10

                NsIcon {
                    icon: "key"
                    color: Theme.textMuted
                    size: 15
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.pam.buffer.length > 0 ? "•".repeat(root.pam.buffer.length) : qsTr("Enter password")
                    color: root.pam.buffer.length > 0 ? Theme.text : Theme.textFaint
                    elide: Text.ElideRight
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.body
                    font.letterSpacing: root.pam.buffer.length > 0 ? 2 : 0
                }

                NsIcon {
                    icon: "login"
                    color: root.pam.buffer.length > 0 ? Colours.palette.m3primary : Theme.textFaint
                    size: 16

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.pam.buffer.length > 0)
                            root.pam.passwd.start()
                    }
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            Layout.preferredHeight: 14
            text: root.errored ? qsTr("Incorrect — try again") : (root.pam.lockMessage || "")
            color: Theme.danger
            font.family: Theme.font.family
            font.pixelSize: 12
        }
    }

    // Bottom strip
    RowLayout {
        z: 11
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 26
        anchors.leftMargin: 28
        anchors.rightMargin: 28

        RowLayout {
            spacing: 10
            visible: Players.active !== null

            Rectangle {
                implicitWidth: 42
                implicitHeight: 42
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)
                NsIcon {
                    anchors.centerIn: parent
                    icon: "music_note"
                    color: Colours.palette.m3primary
                    size: 18
                }
            }

            ColumnLayout {
                spacing: 0
                StyledText {
                    text: Players.active?.trackTitle || ""
                    color: Theme.text
                    elide: Text.ElideRight
                    Layout.maximumWidth: 280
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.bodySmall
                }
                StyledText {
                    text: Players.active?.trackArtist || ""
                    color: Theme.textMuted
                    elide: Text.ElideRight
                    Layout.maximumWidth: 280
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.meta
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            text: qsTr("Press Enter to unlock")
            color: Theme.textFaint
            font.family: Theme.font.family
            font.pixelSize: 11
        }
    }
}
