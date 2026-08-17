pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// First active NetworkManager VPN connection. ponytail: single-VPN-profile
// assumption — extend to a picker if more than one VPN profile ever exists.
Singleton {
    id: root

    property bool connected: false
    property string name: ""

    function poll(): void {
        activeProc.exec(["sh", "-c", "nmcli -t -f NAME,TYPE connection show --active | grep ':vpn$' | head -1 | cut -d: -f1"])
    }

    function toggle(): void {
        if (root.connected) {
            downProc.exec(["nmcli", "connection", "down", root.name])
        } else {
            nameProc.exec(["sh", "-c", "nmcli -t -f NAME,TYPE connection show | grep ':vpn$' | head -1 | cut -d: -f1"])
        }
    }

    Process {
        id: activeProc
        stdout: StdioCollector {
            onStreamFinished: {
                const n = text.trim()
                root.connected = n !== ""
                if (n !== "") root.name = n
            }
        }
    }
    Process { id: downProc; onExited: root.poll() }
    Process {
        id: nameProc
        stdout: StdioCollector {
            onStreamFinished: {
                const n = text.trim()
                if (n !== "") { root.name = n; upProc.exec(["nmcli", "connection", "up", n]) }
            }
        }
    }
    Process { id: upProc; onExited: root.poll() }

    Timer { interval: 5000; repeat: true; running: true; triggeredOnStart: true; onTriggered: root.poll() }
}
