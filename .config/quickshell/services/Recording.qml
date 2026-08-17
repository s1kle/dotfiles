pragma Singleton

import Quickshell
import QtQuick

// wf-recorder start/stop. Optimistic state + pkill-by-name (same pattern as
// NightLight) — tracking the backgrounded pid via the process's own stdout
// doesn't work: wf-recorder inherits that pipe and keeps it open for the
// whole recording, so a StdioCollector's onStreamFinished never fires until
// the recording has already ended.
Singleton {
    id: root

    property bool active: false

    function toggle(): void {
        if (root.active) Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"])
        else Quickshell.execDetached(["sh", "-c",
            'wf-recorder -g "$(slurp)" -f ~/recording_$(date +%Y%m%d_%H%M%S).mp4'])
        root.active = !root.active
    }
}
