pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// Normalised Hyprland workspace lists for the sidebar dots, grouped per
// monitor. Hyprland only tracks workspaces that exist (focused or
// non-empty), so membership ≈ "occupied". rules.lua assigns each monitor a
// contiguous `minSlots`-sized block of workspace ids (1-4, 5-8, ...), so we
// derive each monitor's block from its own workspaces/active workspace
// rather than hardcoding monitor->block mappings here.
Singleton {
    id: root

    property int minSlots: 4
    readonly property var monitors: Hyprland.monitors

    property string tilingLayout: "dwindle"

    // Dots for one monitor only: its own `minSlots`-sized workspace block,
    // independent of which monitor currently has focus.
    function workspacesForMonitor(name: string): var {
        const mon = Hyprland.monitors.values.find(m => m.name === name)
        if (!mon) return []

        const occupied = {}
        let blockBase = mon.activeWorkspace ? Math.floor((mon.activeWorkspace.id - 1) / root.minSlots) * root.minSlots : 0

        for (const ws of Hyprland.workspaces.values) {
            if (ws.id > 0 && ws.monitor && ws.monitor.name === name) {
                occupied[ws.id] = true
                const base = Math.floor((ws.id - 1) / root.minSlots) * root.minSlots
                if (base < blockBase) blockBase = base
            }
        }

        const out = []
        for (let i = 1; i <= root.minSlots; i++) {
            const id = blockBase + i
            out.push({ id, active: mon.activeWorkspace ? id === mon.activeWorkspace.id : false, occupied: !!occupied[id] })
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
