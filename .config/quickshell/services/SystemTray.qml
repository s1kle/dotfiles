pragma Singleton

import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

// Thin wrapper over Quickshell's own SystemTray service — no polling, it's a
// live D-Bus-backed StatusNotifierItem model.
Singleton {
    id: root
    readonly property var items: SystemTray.items.values
}
