pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

// Normalised Hyprland workspace list for the sidebar dots. Hyprland only tracks
// workspaces that exist (focused or non-empty), so membership ≈ "occupied".
// We pad up to at least `minSlots` ids so a fresh session still shows dots.
// ponytail: single flat list, primary-monitor agnostic; add per-monitor grouping
// only if a multi-monitor workspace row is ever needed.
Singleton {
    id: root

    property int minSlots: 4
    readonly property int focusedId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    readonly property var workspaces: {
        const existing = {}
        let maxId = root.minSlots
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id > 0) { existing[ws.id] = true; if (ws.id > maxId) maxId = ws.id }
        }
        const out = []
        for (let i = 1; i <= maxId; i++) {
            out.push({ id: i, active: i === root.focusedId, occupied: !!existing[i] })
        }
        return out
    }

    function switchTo(id: int): void {
        Hyprland.dispatch("workspace " + id)
    }
}
