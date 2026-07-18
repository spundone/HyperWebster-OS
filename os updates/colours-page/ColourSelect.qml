pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// HyperWebster: real Colours settings page (replaces upstream under-construction stub).
PageBase {
    id: root

    title: qsTr("Colours")
    isSubPage: true

    property var schemeData: ({})
    property string currentVariant: ""

    readonly property var schemeNames: {
        const keys = Object.keys(root.schemeData || {});
        return keys.sort((a, b) => {
            if (a === "dynamic")
                return -1;
            if (b === "dynamic")
                return 1;
            return a.localeCompare(b);
        });
    }

    readonly property var flavourNames: {
        const flavours = root.schemeData[Colours.scheme];
        return flavours ? Object.keys(flavours).sort((a, b) => a.localeCompare(b)) : [];
    }

    readonly property var variantDefs: [
        {
            id: "tonalspot",
            name: qsTr("Tonal Spot"),
            description: qsTr("Default Material pastel palette")
        },
        {
            id: "vibrant",
            name: qsTr("Vibrant"),
            description: qsTr("High chroma, punchy primary")
        },
        {
            id: "expressive",
            name: qsTr("Expressive"),
            description: qsTr("Medium chroma with hue shift")
        },
        {
            id: "fidelity",
            name: qsTr("Fidelity"),
            description: qsTr("Stays close to the seed colour")
        },
        {
            id: "content",
            name: qsTr("Content"),
            description: qsTr("Nearly identical to Fidelity")
        },
        {
            id: "fruitsalad",
            name: qsTr("Fruit Salad"),
            description: qsTr("Playful — seed hue is avoided")
        },
        {
            id: "rainbow",
            name: qsTr("Rainbow"),
            description: qsTr("Playful multi-hue palette")
        },
        {
            id: "neutral",
            name: qsTr("Neutral"),
            description: qsTr("Near grayscale with a hint of chroma")
        },
        {
            id: "monochrome",
            name: qsTr("Monochrome"),
            description: qsTr("Fully grayscale")
        }
    ]

    function prettyVariant(id: string): string {
        const hit = root.variantDefs.find(v => v.id === id);
        return hit ? hit.name : (id || "—");
    }

    function setScheme(name: string, flavour: string): void {
        Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-n", name, "-f", flavour]);
    }

    function defaultFlavourFor(name: string): string {
        const flavours = Object.keys(root.schemeData[name] || {});
        if (!flavours.length)
            return Colours.flavour || "default";
        if (name === Colours.scheme && flavours.indexOf(Colours.flavour) >= 0)
            return Colours.flavour;
        if (flavours.indexOf("default") >= 0)
            return "default";
        return flavours.sort((a, b) => a.localeCompare(b))[0];
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Process / Variants must live inside the layout (PageBase default property is Item).
        Process {
            id: listSchemes

            running: true
            command: ["caelestia", "scheme", "list"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        root.schemeData = JSON.parse(text);
                    } catch (e) {
                        root.schemeData = {};
                    }
                }
            }
        }

        Process {
            id: getVariant

            running: true
            command: ["caelestia", "scheme", "get", "-v"]
            stdout: StdioCollector {
                onStreamFinished: root.currentVariant = text.trim()
            }
        }

        Connections {
            target: Colours

            function onSchemeChanged(): void {
                getVariant.running = true;
            }

            function onFlavourChanged(): void {
                getVariant.running = true;
            }
        }

        Variants {
            id: schemeMenu

            model: root.schemeNames

            MenuItem {
                required property string modelData

                text: modelData
                icon: modelData === Colours.scheme ? "check" : "palette"
                activeIcon: "palette"
            }
        }

        Variants {
            id: flavourMenu

            model: root.flavourNames

            MenuItem {
                required property string modelData

                text: modelData
                icon: modelData === Colours.flavour ? "check" : "tune"
                activeIcon: "tune"
            }
        }

        Variants {
            id: variantMenu

            model: root.variantDefs

            MenuItem {
                required property var modelData

                text: modelData.name
                icon: modelData.id === root.currentVariant ? "check" : "palette"
                activeIcon: "palette"
            }
        }

        Process {
            id: syncSddm

            command: ["sh", "-c", "sudo -n /usr/local/bin/sddm-theme-sync 2>/dev/null || kitty --class TUI.float -e sh -c 'sudo /usr/local/bin/sddm-theme-sync; printf \"\\nPress Enter to close...\\n\"; read _'"]
        }

        Process {
            id: themeInstallProc

            command: ["kitty", "--class", "TUI.float", "-e", "hyperwebster-theme", "install"]
            onExited: listSchemes.running = true
        }

        Process {
            id: themeGenerateProc

            command: ["kitty", "--class", "TUI.float", "-e", "sh", "-c", "hyperwebster-theme generate; printf '\\nPress Enter to close...'; read _"]
            onExited: listSchemes.running = true
        }

        Process {
            id: themeTuiProc

            command: ["kitty", "--class", "TUI.float", "-e", "hyperwebster-theme"]
            onExited: listSchemes.running = true
        }

        Process {
            id: themeUpdateProc

            command: ["kitty", "--class", "TUI.float", "-e", "sh", "-c", "hyperwebster-theme update; printf '\\nPress Enter to close...'; read _"]
            onExited: listSchemes.running = true
        }

        // Live palette preview
        SectionHeader {
            first: true
            text: qsTr("Preview")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: previewRow.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: previewRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: [
                            {
                                label: qsTr("Primary"),
                                colour: Colours.palette.m3primary
                            },
                            {
                                label: qsTr("Secondary"),
                                colour: Colours.palette.m3secondary
                            },
                            {
                                label: qsTr("Tertiary"),
                                colour: Colours.palette.m3tertiary
                            },
                            {
                                label: qsTr("Surface"),
                                colour: Colours.palette.m3surface
                            }
                        ]

                        ColumnLayout {
                            required property var modelData

                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            StyledRect {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Tokens.padding.extraLarge * 2
                                color: modelData.colour
                                radius: Tokens.rounding.medium
                            }

                            StyledText {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.label
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("%1 · %2 · %3").arg(Colours.scheme || "—").arg(Colours.flavour || "—").arg(root.prettyVariant(root.currentVariant))
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }
        }

        // Scheme pickers
        SectionHeader {
            text: qsTr("Scheme")
        }

        SelectRow {
            Layout.fillWidth: true
            first: true
            label: qsTr("Colour scheme")
            subtext: qsTr("Presets, or dynamic from the wallpaper")
            menuItems: schemeMenu.instances
            active: menuItems.find(i => i.text === Colours.scheme) ?? null
            fallbackIcon: "palette"
            fallbackText: Colours.scheme || qsTr("…")
            onSelected: item => root.setScheme(item.text, root.defaultFlavourFor(item.text))
        }

        SelectRow {
            Layout.fillWidth: true
            label: qsTr("Flavour")
            subtext: qsTr("Variant within the selected scheme")
            menuItems: flavourMenu.instances
            active: menuItems.find(i => i.text === Colours.flavour) ?? null
            fallbackIcon: "tune"
            fallbackText: Colours.flavour || qsTr("…")
            onSelected: item => root.setScheme(Colours.scheme, item.text)
        }

        SelectRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Material variant")
            subtext: root.variantDefs.find(v => v.id === root.currentVariant)?.description ?? qsTr("How Material You maps the seed colour")
            menuItems: variantMenu.instances
            active: menuItems.find(i => {
                    const def = root.variantDefs.find(v => v.name === i.text);
                    return def && def.id === root.currentVariant;
                }) ?? null
            fallbackIcon: "brush"
            fallbackText: root.prettyVariant(root.currentVariant)
            onSelected: item => {
                const def = root.variantDefs.find(v => v.name === item.text);
                if (def)
                    Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-v", def.id]);
                getVariant.running = true;
            }
        }

        // Theme behaviour
        SectionHeader {
            text: qsTr("Theme")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Dark theme")
            subtext: qsTr("Switch between dark and light mode")
            checked: !Colours.light
            onToggled: Colours.setMode(checked ? "dark" : "light")
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Smart colour scheme")
            subtext: qsTr("Derive mode and variant from the wallpaper")
            checked: GlobalConfig.services.smartScheme
            onToggled: GlobalConfig.services.smartScheme = checked
        }

        // Transparency (frost depth — blur toggle stays on Additions)
        SectionHeader {
            text: qsTr("Transparency")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Transparency")
            subtext: qsTr("Let wallpaper show through shell surfaces")
            checked: Colours.transparency.enabled
            onToggled: GlobalConfig.appearance.transparency.enabled = checked
        }

        SliderRow {
            Layout.fillWidth: true
            enabled: Colours.transparency.enabled
            icon: "gradient"
            label: qsTr("Base opacity")
            valueLabel: Math.round(GlobalConfig.appearance.transparency.base * 100) + "%"
            value: GlobalConfig.appearance.transparency.base
            onMoved: v => GlobalConfig.appearance.transparency.base = Math.round(v * 100) / 100
        }

        SliderRow {
            Layout.fillWidth: true
            last: true
            enabled: Colours.transparency.enabled
            icon: "workspaces"
            label: qsTr("Layer opacity")
            valueLabel: Math.round(GlobalConfig.appearance.transparency.layers * 100) + "%"
            value: GlobalConfig.appearance.transparency.layers
            onMoved: v => GlobalConfig.appearance.transparency.layers = Math.round(v * 100) / 100
        }

        // Omarchy-compatible themes
        SectionHeader {
            text: qsTr("Omarchy themes")
        }

        NavRow {
            first: true
            icon: "extension"
            label: qsTr("Install community theme")
            status: qsTr("Paste a GitHub URL (Omarchy extra themes)")
            onClicked: themeInstallProc.running = true
        }

        NavRow {
            icon: "wallpaper"
            label: qsTr("Generate from wallpaper")
            status: qsTr("Material You → named theme (like Omarchy Aether)")
            onClicked: themeGenerateProc.running = true
        }

        NavRow {
            icon: "palette"
            label: qsTr("Theme picker TUI")
            status: qsTr("Super+Ctrl+Shift+Space")
            onClicked: themeTuiProc.running = true
        }

        NavRow {
            icon: "refresh"
            label: qsTr("Update installed community themes")
            status: qsTr("git pull in ~/.config/omarchy/themes")
            onClicked: themeUpdateProc.running = true
        }

        NavRow {
            last: true
            icon: "globe"
            label: qsTr("Browse Omarchy extra themes")
            status: qsTr("learn.omacom.io catalogue")
            onClicked: Quickshell.execDetached(["xdg-open", "https://learn.omacom.io/2/the-omarchy-manual/90/extra-themes"])
        }

        // Login screen
        SectionHeader {
            text: qsTr("Login screen")
        }

        NavRow {
            first: true
            last: true
            icon: "cloud_sync"
            label: qsTr("Sync login screen colours")
            status: qsTr("Push the current palette to SDDM")
            onClicked: syncSddm.running = true
        }
    }
}
