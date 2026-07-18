import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.nexus.common

// HyperWebster: Settings → About with upstream credits.
PageBase {
    id: root

    // Plugin support is not wired up yet; always 0 for now
    readonly property int pluginCount: 0

    property string quickshellVersion
    property string cliVersion

    title: qsTr("About")

    function openUrl(url: string): void {
        Quickshell.execDetached(["xdg-open", url]);
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // e.g. "Quickshell 0.3.0 (revision ...)"
        Process {
            running: true
            command: ["quickshell", "--version"]
            stdout: StdioCollector {
                onStreamFinished: root.quickshellVersion = text.trim().split(" ")[1] ?? ""
            }
        }

        // Parsed from the caelestia CLI's package listing; the sh wrapper avoids a
        // warning when the (optional) CLI isn't installed
        Process {
            running: true
            command: ["sh", "-c", "caelestia --version 2>/dev/null"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const m = text.match(/caelestia-cli\S*\s+(\d+(?:\.\d+)*)/);
                    root.cliVersion = m ? m[1] : "";
                }
            }
        }

        // Hero
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: hero.implicitHeight + Tokens.padding.extraLarge * 2

            ColumnLayout {
                id: hero

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                spacing: Tokens.spacing.small

                Image {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 104
                    Layout.preferredHeight: 104
                    source: Quickshell.shellDir + "/assets/hyperwebster-logo.png"
                    sourceSize.width: 208
                    sourceSize.height: 208
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.small
                    text: "HyperWebster"
                    font: Tokens.font.headline.builders.large.width(110).build()
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "hyperarch"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.extraSmall
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("Personal vibecoded desktop ISO - experimental and untested. Built on excellent upstream work.")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }
            }
        }

        // System
        SectionHeader {
            text: qsTr("System")
        }

        InfoRow {
            first: true
            label: qsTr("Hostname")
            value: SysInfo.hostname
        }

        InfoRow {
            label: qsTr("Device")
            value: SysInfo.device
        }

        InfoRow {
            label: qsTr("Distro")
            value: SysInfo.osPrettyName || SysInfo.osName
        }

        InfoRow {
            label: qsTr("Kernel")
            value: SysInfo.kernel
        }

        InfoRow {
            last: true
            label: qsTr("Firmware")
            value: SysInfo.firmware
        }

        // Software
        SectionHeader {
            text: qsTr("Software")
        }

        InfoRow {
            first: true
            label: qsTr("Shell")
            value: CUtils.version || "…"
        }

        InfoRow {
            label: qsTr("CLI")
            value: root.cliVersion || "…"
        }

        InfoRow {
            label: qsTr("Quickshell")
            value: root.quickshellVersion || "…"
        }

        InfoRow {
            last: true
            label: qsTr("Qt")
            value: CUtils.qtVersion || "…"
        }

        // Credits
        SectionHeader {
            text: qsTr("Credits")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: creditsBlurb.implicitHeight + Tokens.padding.large * 2

            StyledText {
                id: creditsBlurb

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                wrapMode: Text.WordWrap
                text: qsTr("HyperWebster bundles, themes, and installs upstream projects - it does not replace them. Please support the originals; each remains under its own licence.")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }
        }

        SectionHeader {
            text: qsTr("Lineage")
        }

        NavRow {
            first: true
            icon: "build"
            label: "NoSignal OS"
            status: qsTr("ISO builder and layer architecture")
            onClicked: root.openUrl("https://github.com/28allday/NoSignal-OS")
        }

        NavRow {
            last: true
            icon: "schedule"
            label: "hyperarch"
            status: qsTr("Earlier naming and design intent")
            onClicked: root.openUrl("https://github.com/spundone/HyperWebster-OS")
        }

        SectionHeader {
            text: qsTr("Desktop & shell")
        }

        NavRow {
            first: true
            icon: "globe"
            label: "Arch Linux"
            status: qsTr("Base distribution")
            onClicked: root.openUrl("https://archlinux.org")
        }

        NavRow {
            icon: "web_asset"
            label: "Hyprland"
            status: qsTr("Wayland compositor")
            onClicked: root.openUrl("https://hyprland.org")
        }

        NavRow {
            icon: "palette"
            label: "caelestia"
            status: qsTr("Dotfiles, shell UX, theming")
            onClicked: root.openUrl("https://github.com/caelestia-dots/caelestia")
        }

        NavRow {
            icon: "widgets"
            label: "nosignal-shell"
            status: qsTr("Pinned shell fork (28allday)")
            onClicked: root.openUrl("https://github.com/28allday/nosignal-shell")
        }

        NavRow {
            icon: "extension"
            label: "Quickshell"
            status: qsTr("Shell runtime")
            onClicked: root.openUrl("https://quickshell.outfoxxed.me")
        }

        NavRow {
            last: true
            icon: "settings"
            label: "SDDM"
            status: qsTr("Display manager")
            onClicked: root.openUrl("https://github.com/sddm/sddm")
        }

        SectionHeader {
            text: qsTr("Inspiration & tooling")
        }

        NavRow {
            first: true
            icon: "bolt"
            label: "Omarchy"
            status: qsTr("Keys, themes, install menu, Plymouth UX")
            onClicked: root.openUrl("https://omarchy.org")
        }

        NavRow {
            icon: "tune"
            label: "CachyOS"
            status: qsTr("Kernel, repos, kernel manager")
            onClicked: root.openUrl("https://github.com/CachyOS/CachyOS")
        }

        NavRow {
            icon: "apps"
            label: "ChimeraOS / Deckify / DeckShift"
            status: qsTr("Gamescope session stack")
            onClicked: root.openUrl("https://chimeraos.org")
        }

        NavRow {
            icon: "system_update_alt"
            label: "Limine"
            status: qsTr("UEFI bootloader")
            onClicked: root.openUrl("https://github.com/limine-bootloader/limine")
        }

        NavRow {
            last: true
            icon: "wifi"
            label: "Tailscale"
            status: qsTr("Mesh VPN (preinstalled)")
            onClicked: root.openUrl("https://tailscale.com")
        }

        SectionHeader {
            text: qsTr("More")
        }

        NavRow {
            first: true
            icon: "info"
            label: qsTr("Full credits")
            status: qsTr("docs/CREDITS.md on GitHub")
            onClicked: root.openUrl("https://github.com/spundone/HyperWebster-OS/blob/main/docs/CREDITS.md")
        }

        NavRow {
            icon: "dashboard"
            label: qsTr("Source repository")
            status: "spundone/HyperWebster-OS"
            onClicked: root.openUrl("https://github.com/spundone/HyperWebster-OS")
        }

        NavRow {
            last: true
            icon: "settings"
            label: qsTr("Maintainer")
            status: "Spandan (spundone)"
            onClicked: root.openUrl("https://github.com/spundone")
        }

        // Plugins
        SectionHeader {
            text: qsTr("Plugins")
        }

        InfoRow {
            first: true
            last: true
            label: qsTr("Loaded plugins")
            value: root.pluginCount.toString()
        }
    }
}
