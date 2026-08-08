pragma Singleton

import Quickshell
import Quickshell.Wayland
import QtQuick

// The globally-focused toplevel (any monitor), resolved to a display name + icon
// via DesktopEntries.
Singleton {
    id: root

    readonly property var active: ToplevelManager.activeToplevel
    readonly property string appId: active ? active.appId : ""
    readonly property string title: active ? active.title : ""

    readonly property var entry: root.appId ? DesktopEntries.heuristicLookup(root.appId) : null
    readonly property string name: entry ? entry.name : (root.title || root.appId)
    readonly property string icon: entry ? entry.icon : ""
}
