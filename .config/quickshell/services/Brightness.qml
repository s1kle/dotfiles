pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Backlight brightness via brightnessctl. value is 0..1. set() is optimistic
// (updates value immediately, then applies), so a bound slider feels instant.
Singleton {
    id: root

    property real value: 0
    property bool available: false

    function set(v: real): void {
        root.value = Math.max(0, Math.min(1, v))
        setProc.exec(["brightnessctl", "-q", "set", Math.round(root.value * 100) + "%"])
    }

    function refresh(): void { infoProc.exec(["brightnessctl", "-m", "i"]) }

    Process {
        id: infoProc
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",") // name,class,current,percent,max
                const max = f.length >= 5 ? Number(f[4]) : 0
                if (max > 0) {
                    root.value = Number(f[2]) / max
                    root.available = true
                } else {
                    root.available = false
                }
            }
        }
    }

    Process {
        id: setProc
        onExited: root.refresh() // resync after applying
    }

    Timer { interval: 5000; repeat: true; running: true; onTriggered: root.refresh() }
    Component.onCompleted: root.refresh()
}
