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
        if (checked)
            enableProc.running = true;   // needs a password -> floating terminal
        else
            disableProc.running = true;  // no password inside the active window
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
        command: ["kitty", "--class", "TUI.float", "-e", "sudo", "hyperwebster-sudo-toggle", "enable"]
    }
    Process {
        id: disableProc
        command: ["sudo", "-n", "hyperwebster-sudo-toggle", "disable"]
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
