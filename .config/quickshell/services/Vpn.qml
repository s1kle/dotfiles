pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Headless Hiddify proxy control -- ~/.config/hypr/scripts/hiddify-instance.sh
// runs HiddifyCli (the core the Hiddify GUI itself shells out to) as a
// systemd --user unit; see that script for why we bypass the GUI, which
// needs a display quickshell/SSH don't have. Two modes: tun (real VPN) and
// proxy (system-proxy only); toggle() connects/disconnects in the current
// mode, toggleMode() flips it, reconnecting immediately if already connected
// so the switch is visible.
Singleton {
    id: root

    readonly property string script: "~/.config/hypr/scripts/hiddify-instance.sh"

    property bool connected: false
    property string mode: "tun" // "tun" | "proxy"

    function poll(): void {
        pollProc.exec(["sh", "-c", script + " status"])
    }

    function toggle(): void {
        const cmd = root.connected ? "stop" : ("start " + root.mode)
        ctlProc.exec(["sh", "-c", script + " " + cmd])
    }

    function toggleMode(): void {
        root.mode = root.mode === "tun" ? "proxy" : "tun"
        if (root.connected) ctlProc.exec(["sh", "-c", script + " stop && " + script + " start " + root.mode])
    }

    Process {
        id: pollProc
        stdout: StdioCollector {
            onStreamFinished: root.connected = text.trim() === "active"
        }
    }
    Process { id: ctlProc; onExited: root.poll() }

    Timer { interval: 5000; repeat: true; running: true; triggeredOnStart: true; onTriggered: root.poll() }
}
