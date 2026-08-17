pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Pending pacman + AUR update count, polled every 30 minutes.
Singleton {
    id: root

    property int count: 0

    function poll(): void {
        proc.exec(["sh", "-c", "checkupdates 2>/dev/null | wc -l; yay -Qua 2>/dev/null | wc -l"])
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                const n = text.trim().split("\n").map(Number).filter(Number.isFinite)
                root.count = n.reduce((a, b) => a + b, 0)
            }
        }
    }

    Timer { interval: 30 * 60 * 1000; repeat: true; running: true; triggeredOnStart: true; onTriggered: root.poll() }
}
