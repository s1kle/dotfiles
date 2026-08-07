pragma Singleton

import Quickshell
import QtQuick

// App-menu entries parsed from installed .desktop files. Each entry exposes:
//   icon (string or null), name, path (executable), arguments (list).
// Terminal apps (Terminal=true) are wrapped as `<terminal> -e <cmd…>`
// e.g. btop -> { path: "kitty", arguments: ["-e", "btop"] }.
// launch(entry) runs path + arguments detached.
Singleton {
    id: root

    readonly property string terminal: Quickshell.env("TERMINAL") || "kitty"

    readonly property var list: root.build(DesktopEntries.applications.values)

    function build(apps: var): var {
        const out = []
        for (const app of apps) {
            if (app.noDisplay)
                continue
            const cmd = Array.from(app.command)
            if (cmd.length === 0)
                continue
            const inTerm = app.runInTerminal
            out.push({
                icon: app.icon || null,
                name: app.name || cmd[0],
                path: inTerm ? root.terminal : cmd[0],
                arguments: inTerm ? ["-e"].concat(cmd) : cmd.slice(1)
            })
        }
        out.sort((a, b) => (a.name || "").localeCompare(b.name || ""))
        return out
    }

    function launch(entry: var): void {
        Quickshell.execDetached([entry.path].concat(entry.arguments))
    }
}
