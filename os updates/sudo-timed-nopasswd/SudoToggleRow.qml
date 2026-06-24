// SudoToggleRow.qml (HyperWebster) — Settings -> Services toggle for time-boxed
// passwordless sudo. Reflects live state by polling `hyperwebster-sudo-toggle
// status` (no root needed); enabling opens a floating terminal for the ONE
// password prompt, disabling runs passwordless inside the active window.
//
// Untracked file under modules/nexus/common — auto-discovered as the type
// `SudoToggleRow` via `import qs.modules.nexus.common`. Survives caelestia
// upgrades; only the one-line insert in ServicesPage.qml is re-applied by hook.
import QtQuick
import Quickshell.Io
import qs.modules.nexus.common

ToggleRow {
    id: root

    property bool active: false
    property int remaining: 0

    text: qsTr("Passwordless sudo (15 min)")
    subtext: active
        ? qsTr("On — %1 min left. Auto-reverts; a reboot also clears it.").arg(remaining)
        : qsTr("Run sudo without a password for 15 minutes, then it reverts")

    onToggled: {
        if (checked) {
            enableProc.running = true;   // needs a password -> floating terminal
            focusTimer.ticks = 0;
            focusTimer.restart();        // then pull keyboard focus to the prompt
        } else {
            disableProc.running = true;  // no password inside the active window
        }
        reconcile.restart();
    }

    // --- live state -----------------------------------------------------------
    Process {
        id: statusProc
        command: ["hyperwebster-sudo-toggle", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(/\s+/);
                root.active = p[0] === "active";
                root.remaining = parseInt(p[1] || "0") || 0;
                root.checked = root.active;   // drive switch from real state
            }
        }
    }

    // --- actions --------------------------------------------------------------
    Process {
        id: enableProc
        // Dedicated window class (hyperwebster-sudo) so the shipped hypr windowrules
        // (float/center/pin/stayfocused) force this prompt to GRAB keyboard focus.
        command: ["kitty", "--class", "hyperwebster-sudo", "-e", "hyperwebster-sudo-toggle", "enable-tui"]
    }
    Process {
        id: disableProc
        command: ["sudo", "-n", "hyperwebster-sudo-toggle", "disable"]
    }
    Process {
        id: focusProc
        command: ["hyprctl", "dispatch", "focuswindow", "class:^(hyperwebster-sudo)$"]
    }
    Timer {
        id: focusTimer
        interval: 400
        repeat: true
        triggeredOnStart: false
        property int ticks: 0
        onTriggered: {
            focusProc.running = true;
            ticks += 1;
            if (ticks >= 3) {
                ticks = 0;
                stop();
            }
        }
    }

    // --- polling --------------------------------------------------------------
    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: statusProc.running = true
    }
    Timer {
        id: reconcile
        interval: 2000
        onTriggered: statusProc.running = true
    }
}
