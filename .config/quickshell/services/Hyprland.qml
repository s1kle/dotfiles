pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
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
    readonly property string monitorName: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""

    property string tilingLayout: "dwindle"

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

    // hyprctl (not Hyprland.dispatch): the latter is evaluated as Lua on some
    // Hyprland builds, mangling "workspace 2"; hyprctl's dispatch path is
    // version-agnostic across the VM and the laptop.
    function switchTo(id: int): void {
        switchProc.exec(["hyprctl", "dispatch", "workspace", String(id)])
    }

    Process { id: switchProc }

    // this build's Hyprland config is Lua-driven; `hyprctl keyword` is
    // rejected ("can't work with non-legacy parsers") so runtime layout
    // changes go through the same Lua REPL the config itself loads via
    // (hl.config takes one table, matching hyprland.lua's nested shape).
    function toggleLayout(): void {
        const next = root.tilingLayout === "master" ? "dwindle" : "master"
        toggleLayoutProc.exec(["hyprctl", "repl", `hl.config({general = {layout = "${next}"}})`])
        root.tilingLayout = next
    }

    Process { id: toggleLayoutProc }

    Process {
        id: layoutProc
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.tilingLayout = JSON.parse(text).str || "dwindle" }
                catch (e) { /* keep last-good */ }
            }
        }
    }

    Timer {
        interval: 2000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: layoutProc.exec(["hyprctl", "-j", "getoption", "general:layout"])
    }
}
