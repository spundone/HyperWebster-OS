// CachyRepoToggleRow.qml (HyperWebster) — Settings -> Services toggle to enable /
// disable the CachyOS pacman repositories. Auto-detects the best x86-64 microarch
// tier the CPU supports (v4 > v3). Live state polls `hyperwebster-cachy-repo status`
// (no root). enable/disable run in a floating terminal so the pacman/download
// output stays visible; the grant is passwordless via sudo -n
// (/etc/sudoers.d/02-hyperwebster-cachy). enable adds repos, converts userspace to
// the optimized builds (pacman -Suu, pacman pinned stock), and installs the
// linux-cachyos kernel; disable reverts to stock and removes the cachy kernel
// (keeping stock `linux` bootable). A reboot switches the running kernel.
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

    text: qsTr("CachyOS repositories")
    subtext: repoOn
        ? qsTr("On — CachyOS optimized builds + linux-cachyos kernel (reboot to run it)")
        : qsTr("Switch to CachyOS optimized builds + linux-cachyos kernel (reboot after)")

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
