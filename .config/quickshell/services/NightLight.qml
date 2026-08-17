pragma Singleton

import Quickshell
import QtQuick

// hyprsunset toggle. Optimistic state (hyprsunset has no query flag) —
// same pattern as other toggle-only external-tool services here.
Singleton {
    id: root

    property bool enabled: false

    function toggle(): void {
        if (root.enabled) Quickshell.execDetached(["pkill", "-x", "hyprsunset"])
        else Quickshell.execDetached(["hyprsunset", "-t", "4000"])
        root.enabled = !root.enabled
    }
}
