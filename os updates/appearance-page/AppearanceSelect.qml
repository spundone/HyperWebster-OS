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

// HyperWebster: Appearance customization under Wallpaper & style.
PageBase {
    id: root

    title: qsTr("Appearance")
    isSubPage: true

    property var hypr: ({
            windowRadius: 0,
            gapsIn: 4,
            gapsOut: 8,
            workspaceGaps: 10,
            singleGapsOut: 12,
            windowOpacity: 1.0,
            borderSize: 1
        })

    function applyHypr(key: string, value): void {
        Quickshell.execDetached(["hyperwebster-appearance", "set", key, String(value)]);
        statusProc.running = true;
    }

    function syncShellFromHypr(): void {
        if (root.hypr.roundingScale !== undefined)
            GlobalConfig.appearance.rounding.scale = root.hypr.roundingScale;
        if (root.hypr.spacingScale !== undefined)
            GlobalConfig.appearance.spacing.scale = root.hypr.spacingScale;
        if (root.hypr.paddingScale !== undefined)
            GlobalConfig.appearance.padding.scale = root.hypr.paddingScale;
        if (root.hypr.fontScale !== undefined)
            GlobalConfig.appearance.font.scale = root.hypr.fontScale;
        if (root.hypr.animScale !== undefined)
            GlobalConfig.appearance.anim.durations.scale = root.hypr.animScale;
        if (root.hypr.deformScale !== undefined)
            GlobalConfig.appearance.deformScale = root.hypr.deformScale;
    }

    function applyPreset(name: string): void {
        presetProc.command = ["hyperwebster-appearance", "preset", name];
        presetProc.running = true;
    }

    readonly property var uiFontChoices: [
        {
            id: "JetBrainsMono Nerd Font",
            name: qsTr("JetBrains Mono (default)")
        },
        {
            id: "CaskaydiaCove NF",
            name: "CaskaydiaCove NF"
        },
        {
            id: "GoogleSansFlex",
            name: "Google Sans Flex"
        },
        {
            id: "Inter",
            name: "Inter"
        },
        {
            id: "Noto Sans",
            name: "Noto Sans"
        },
        {
            id: "Rubik",
            name: "Rubik"
        },
        {
            id: "IBM Plex Sans",
            name: "IBM Plex Sans"
        },
        {
            id: "Source Sans 3",
            name: "Source Sans 3"
        }
    ]

    readonly property var monoFontChoices: [
        {
            id: "JetBrainsMono Nerd Font",
            name: qsTr("JetBrains Mono (default)")
        },
        {
            id: "CaskaydiaCove NF",
            name: "CaskaydiaCove NF"
        },
        {
            id: "Fira Code",
            name: "Fira Code"
        },
        {
            id: "Source Code Pro",
            name: "Source Code Pro"
        },
        {
            id: "IBM Plex Mono",
            name: "IBM Plex Mono"
        },
        {
            id: "Hack",
            name: "Hack"
        }
    ]

    readonly property string currentUiFont: GlobalConfig.appearance.font.body.family || "JetBrainsMono Nerd Font"
    readonly property string currentMonoFont: GlobalConfig.appearance.font.mono.family || "JetBrainsMono Nerd Font"

    function applyUiFont(family: string): void {
        GlobalConfig.appearance.font.headline.family = family;
        GlobalConfig.appearance.font.title.family = family;
        GlobalConfig.appearance.font.body.family = family;
        GlobalConfig.appearance.font.label.family = family;
        GlobalConfig.appearance.font.clock = family;
        root.applyHypr("font-family", family);
    }

    function applyMonoFont(family: string): void {
        GlobalConfig.appearance.font.mono.family = family;
        root.applyHypr("font-mono", family);
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Process {
            id: statusProc

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
            id: presetProc

            onExited: refreshAndSync.running = true
        }

        Process {
            id: refreshAndSync

            command: ["hyperwebster-appearance", "status-json"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        root.hypr = Object.assign({}, root.hypr, JSON.parse(text));
                        root.syncShellFromHypr();
                    } catch (e) {}
                }
            }
        }

        Variants {
            id: uiFontMenu

            model: root.uiFontChoices

            MenuItem {
                required property var modelData

                text: modelData.name
                icon: modelData.id === root.currentUiFont ? "check" : "text_fields"
                activeIcon: "text_fields"
            }
        }

        Variants {
            id: monoFontMenu

            model: root.monoFontChoices

            MenuItem {
                required property var modelData

                text: modelData.name
                icon: modelData.id === root.currentMonoFont ? "check" : "code"
                activeIcon: "code"
            }
        }

        // Live preview
        SectionHeader {
            first: true
            text: qsTr("Preview")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: previewCol.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: previewCol

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    Repeater {
                        model: [0.55, 0.75, 1.0]

                        Rectangle {
                            required property real modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            radius: Math.round(Tokens.rounding.large * modelData)
                            color: Colours.palette.m3primaryContainer

                            StyledText {
                                anchors.centerIn: parent
                                text: Math.round(parent.radius) + "px"
                                color: Colours.palette.m3onPrimaryContainer
                                font: Tokens.font.label.small
                            }
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Shell scale %1 · Window radius %2px").arg(Number(GlobalConfig.appearance.rounding.scale).toFixed(2)).arg(root.hypr.windowRadius ?? 0)
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }
        }

        // Presets
        SectionHeader {
            text: qsTr("Presets")
        }

        NavRow {
            first: true
            icon: "web_asset"
            label: qsTr("Flat (HyperWebster default)")
            status: qsTr("Square corners, tight gaps")
            onClicked: root.applyPreset("flat")
        }

        NavRow {
            icon: "tune"
            label: qsTr("Mild rounded")
            status: qsTr("8px windows · scale 1.0")
            onClicked: root.applyPreset("mild")
        }

        NavRow {
            icon: "gradient"
            label: qsTr("Soft")
            status: qsTr("12px · slightly airy")
            onClicked: root.applyPreset("soft")
        }

        NavRow {
            icon: "water_drop"
            label: qsTr("Pillowy")
            status: qsTr("18px · roomy gaps")
            onClicked: root.applyPreset("pillowy")
        }

        NavRow {
            last: true
            icon: "filter_b_and_w"
            label: qsTr("Glass")
            status: qsTr("Rounded + transparency + blur")
            onClicked: root.applyPreset("glass")
        }

        // Corners
        SectionHeader {
            text: qsTr("Corners")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Rounded corners")
            subtext: qsTr("Enable shell rounding tokens (same as Additions)")
            checked: GlobalConfig.appearance.rounding.scale > 0.01
            onToggled: {
                if (checked) {
                    Quickshell.execDetached(["sh", "-c", "hyperwebster-appearance ensure-rounding; hyperwebster-appearance set rounding-scale 1; hyperwebster-appearance set window-radius 8"]);
                    GlobalConfig.appearance.rounding.scale = 1;
                } else {
                    Quickshell.execDetached(["hyperwebster-rounding-toggle", "disable"]);
                    GlobalConfig.appearance.rounding.scale = 0;
                }
                statusProc.running = true;
            }
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Shell corner scale")
            subtext: qsTr("Multiplies shell UI radii (0 = square)")
            value: Math.round(GlobalConfig.appearance.rounding.scale * 100)
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => {
                const s = v / 100;
                GlobalConfig.appearance.rounding.scale = s;
                if (s > 0)
                    Quickshell.execDetached(["hyperwebster-appearance", "ensure-rounding"]);
                root.applyHypr("rounding-scale", s);
            }
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Window corner radius")
            subtext: qsTr("Hyprland $windowRounding (pixels)")
            value: root.hypr.windowRadius ?? 0
            from: 0
            to: 32
            stepSize: 1
            onMoved: v => {
                root.hypr.windowRadius = v;
                root.applyHypr("window-radius", v);
            }
        }

        // Typography
        SectionHeader {
            text: qsTr("Typography")
        }

        SelectRow {
            Layout.fillWidth: true
            first: true
            label: qsTr("UI font")
            subtext: qsTr("Settings and Tokens — top bar chrome stays JetBrainsMono Nerd Font")
            menuItems: uiFontMenu.instances
            active: menuItems.find(i => {
                    const def = root.uiFontChoices.find(v => v.name === i.text);
                    return def && def.id === root.currentUiFont;
                }) ?? null
            fallbackIcon: "text_fields"
            fallbackText: root.uiFontChoices.find(v => v.id === root.currentUiFont)?.name ?? root.currentUiFont
            onSelected: item => {
                const def = root.uiFontChoices.find(v => v.name === item.text);
                if (def)
                    root.applyUiFont(def.id);
            }
        }

        SelectRow {
            Layout.fillWidth: true
            label: qsTr("Monospace font")
            subtext: qsTr("Terminals and mono UI text")
            menuItems: monoFontMenu.instances
            active: menuItems.find(i => {
                    const def = root.monoFontChoices.find(v => v.name === i.text);
                    return def && def.id === root.currentMonoFont;
                }) ?? null
            fallbackIcon: "code"
            fallbackText: root.monoFontChoices.find(v => v.id === root.currentMonoFont)?.name ?? root.currentMonoFont
            onSelected: item => {
                const def = root.monoFontChoices.find(v => v.name === item.text);
                if (def)
                    root.applyMonoFont(def.id);
            }
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Font scale")
            subtext: qsTr("Shell typography size (%)")
            value: Math.round(GlobalConfig.appearance.font.scale * 100)
            from: 75
            to: 150
            stepSize: 5
            onMoved: v => {
                GlobalConfig.appearance.font.scale = v / 100;
                root.applyHypr("font-scale", v / 100);
            }
        }

        // Density
        SectionHeader {
            text: qsTr("Density")
        }

        StepperRow {
            Layout.fillWidth: true
            first: true
            label: qsTr("Spacing scale")
            subtext: qsTr("Gaps between shell elements (%)")
            value: Math.round(GlobalConfig.appearance.spacing.scale * 100)
            from: 50
            to: 150
            stepSize: 5
            onMoved: v => {
                GlobalConfig.appearance.spacing.scale = v / 100;
                root.applyHypr("spacing-scale", v / 100);
            }
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Padding scale")
            subtext: qsTr("Inner padding on panels and rows (%)")
            value: Math.round(GlobalConfig.appearance.padding.scale * 100)
            from: 50
            to: 150
            stepSize: 5
            onMoved: v => {
                GlobalConfig.appearance.padding.scale = v / 100;
                root.applyHypr("padding-scale", v / 100);
            }
        }

        // Windows / Hyprland
        SectionHeader {
            text: qsTr("Windows")
        }

        StepperRow {
            Layout.fillWidth: true
            first: true
            label: qsTr("Inner gaps")
            subtext: qsTr("Between tiled windows")
            value: root.hypr.gapsIn ?? 4
            from: 0
            to: 24
            stepSize: 1
            onMoved: v => {
                root.hypr.gapsIn = v;
                root.applyHypr("gaps-in", v);
            }
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Outer gaps")
            subtext: qsTr("Between windows and screen edge")
            value: root.hypr.gapsOut ?? 8
            from: 0
            to: 40
            stepSize: 1
            onMoved: v => {
                root.hypr.gapsOut = v;
                root.applyHypr("gaps-out", v);
            }
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Workspace gaps")
            subtext: qsTr("Reserved workspace padding")
            value: root.hypr.workspaceGaps ?? 10
            from: 0
            to: 48
            stepSize: 1
            onMoved: v => {
                root.hypr.workspaceGaps = v;
                root.applyHypr("workspace-gaps", v);
            }
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Single-window outer gaps")
            subtext: qsTr("When only one tiled window is open")
            value: root.hypr.singleGapsOut ?? 12
            from: 0
            to: 64
            stepSize: 1
            onMoved: v => {
                root.hypr.singleGapsOut = v;
                root.applyHypr("single-gaps-out", v);
            }
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Window opacity")
            subtext: qsTr("Active window opacity (%)")
            value: Math.round((root.hypr.windowOpacity ?? 1) * 100)
            from: 70
            to: 100
            stepSize: 1
            onMoved: v => {
                root.hypr.windowOpacity = v / 100;
                root.applyHypr("window-opacity", (v / 100).toFixed(2));
            }
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Border size")
            subtext: qsTr("Window border thickness (px)")
            value: root.hypr.borderSize ?? 1
            from: 0
            to: 6
            stepSize: 1
            onMoved: v => {
                root.hypr.borderSize = v;
                root.applyHypr("border-size", v);
            }
        }

        // Motion
        SectionHeader {
            text: qsTr("Motion")
        }

        StepperRow {
            Layout.fillWidth: true
            first: true
            label: qsTr("Animation duration")
            subtext: qsTr("Shell transition speed (%) — lower is snappier")
            value: Math.round(GlobalConfig.appearance.anim.durations.scale * 100)
            from: 40
            to: 160
            stepSize: 5
            onMoved: v => {
                GlobalConfig.appearance.anim.durations.scale = v / 100;
                root.applyHypr("anim-scale", v / 100);
            }
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Drawer deform")
            subtext: qsTr("Side-drawer blob stretch (%)")
            value: Math.round(GlobalConfig.appearance.deformScale * 100)
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => {
                GlobalConfig.appearance.deformScale = v / 100;
                root.applyHypr("deform-scale", v / 100);
            }
        }

        // Glass (shortcuts)
        SectionHeader {
            text: qsTr("Glass & effects")
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
            enabled: Colours.transparency.enabled
            icon: "workspaces"
            label: qsTr("Layer opacity")
            valueLabel: Math.round(GlobalConfig.appearance.transparency.layers * 100) + "%"
            value: GlobalConfig.appearance.transparency.layers
            onMoved: v => GlobalConfig.appearance.transparency.layers = Math.round(v * 100) / 100
        }

        NavRow {
            icon: "filter_b_and_w"
            label: qsTr("Frosted glass blur")
            status: qsTr("Additions toggle · Hyprland layerrules")
            onClicked: Quickshell.execDetached(["sh", "-c", "hyperwebster-blur-toggle toggle; notify-send 'Blur' \"$(hyperwebster-blur-toggle status)\" 2>/dev/null || true"])
        }

        NavRow {
            icon: "bolt"
            label: qsTr("Hypersmooth 120/144 Hz")
            status: qsTr("Snappier shell animation durations")
            onClicked: Quickshell.execDetached(["sh", "-c", "hyperwebster-hypersmooth-toggle toggle 2>/dev/null; notify-send 'Hypersmooth' toggled 2>/dev/null || true"])
        }

        NavRow {
            last: true
            icon: "shuffle"
            label: qsTr("Zephyr motion polish")
            status: qsTr("Overshoot flair on shell animations")
            onClicked: Quickshell.execDetached(["sh", "-c", "hyperwebster-zephyr-polish toggle 2>/dev/null; notify-send 'Zephyr' toggled 2>/dev/null || true"])
        }

        SectionHeader {
            text: qsTr("More")
        }

        NavRow {
            first: true
            last: true
            icon: "palette"
            label: qsTr("Colours & themes")
            status: qsTr("Schemes, Omarchy packs, wallpaper gen")
            onClicked: root.nState.openSubPage(3)
        }
    }
}
