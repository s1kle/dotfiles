pragma Singleton

import Quickshell
import Quickshell.Services.Notifications

// Freedesktop notification server. Exposes tracked (live) notifications as a
// list for the UI; each item has appName/summary/body/image/dismiss().
Singleton {
    id: root

    readonly property var model: server.trackedNotifications
    readonly property var list: server.trackedNotifications.values
    property bool dnd: false
    function toggleDnd(): void { root.dnd = !root.dnd }

    NotificationServer {
        id: server
        keepOnReload: false
        bodySupported: true
        imageSupported: true
        actionsSupported: false

        onNotification: n => { n.tracked = true }
    }
}
