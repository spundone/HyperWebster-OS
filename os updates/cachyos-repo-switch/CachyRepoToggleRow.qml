// CachyRepoToggleRow.qml (HyperWebster) — Settings -> Services toggle to revert
// to stock Arch kernel/repos or re-enable CachyOS optimized builds. Fresh installs
// ship linux-cachyos + CachyOS repos OOB; this toggle is mainly for reverting.
// Auto-detects the best x86-64 microarch tier (v4 > v3). Live state polls
// `hyperwebster-cachy-repo status` (no root). enable/disable run in a floating
// terminal so pacman output stays visible; passwordless via sudo -n.
//
// Untracked file under modules/nexus/common — auto-discovered as the type
// `CachyRepoToggleRow` via `import qs.modules.nexus.common`. Survives caelestia
// upgrades; pairs with the one-line insert in ServicesPage.qml.
import QtQuick
import Quickshell.Io
import qs.modules.nexus.common

ToggleRow {
    id: root

    property bool repoOn: false   // NB: not `enabled` (reserved Item property)

    text: qsTr("CachyOS kernel & repos")
    subtext: repoOn
        ? qsTr("On — linux-cachyos + optimized repos (toggle off to revert to stock)")
        : qsTr("Off — stock Arch kernel and repos (toggle on to re-enable CachyOS)")

    onToggled: {
        if (checked)
            enableProc.running = true;
        else
            disableProc.running = true;
        reconcile.restart();
    }

    // --- live state -----------------------------------------------------------
    Process {
        id: statusProc
        command: ["/usr/local/bin/hyperwebster-cachy-repo", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.repoOn = text.trim() === "enabled";
                root.checked = root.repoOn;   // drive switch from real state
            }
        }
    }

    // --- actions (passwordless; shown in a terminal for pacman output) ---------
    Process {
        id: enableProc
        command: ["kitty", "--class", "TUI.float", "-e", "sh", "-c", "sudo -n /usr/local/bin/hyperwebster-cachy-repo enable; printf '\\nPress Enter to close...'; read _"]
        onExited: reconcile.restart()
    }
    Process {
        id: disableProc
        command: ["kitty", "--class", "TUI.float", "-e", "sh", "-c", "sudo -n /usr/local/bin/hyperwebster-cachy-repo disable; printf '\\nPress Enter to close...'; read _"]
        onExited: reconcile.restart()
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
