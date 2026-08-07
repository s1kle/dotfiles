pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string hostname: ""
    property bool valid: false

    // QML-side defaults; JSON files override these. Section objects are
    // replaced wholesale on reload so widget bindings re-evaluate.
    property var defaults: {
        theme: { name: "NordTheme" },
        layout: { barHeight: 34, barWidth: 700, radius: 12, padding: 8, margin: 6, gap: 4 },
        shadow: { blur: 16, offsetY: 2, opacity: 0.35 },
        font: { family: "Inter", sizes: { bar: 12, clock: 14, title: 11 } },
        widgets: { Music: true, Weather: true, Workspaces: true, Settings: true, Battery: true, Bluetooth: true },
    }

    property var theme: defaults.theme
    property var layout: defaults.layout
    property var shadow: defaults.shadow
    property var font: defaults.font
    property var widgets: defaults.widgets

    property string baseText: ""
    property string hostText: ""
    property bool warnedInvalid: false

    function parseJson(text: string): var {
        try {
            return JSON.parse(text)
        } catch (e) {
            if (!root.warnedInvalid) {
                console.warn(`Config: invalid JSON, keeping last good state: ${e?.message ?? e}`)
                root.warnedInvalid = true
            }
            return null
        }
    }

    // Merge driven by base keys: override keys absent from base are ignored,
    // objects recurse, scalars/arrays are replaced wholesale.
    function deepMerge(base: var, override: var): var {
        if (override === undefined || override === null) return base
        if (typeof base !== "object" || typeof override !== "object") return override
        const out = {}
        for (const key of Object.keys(base)) {
            out[key] = root.deepMerge(base[key], override[key])
        }
        return out
    }

    function reapply(): void {
        const base = root.parseJson(root.baseText)
        const host = root.parseJson(root.hostText)
        if (root.baseText === "" && root.hostText === "") return
        if (base === null && host === null) return // keep last good state
        let merged = root.defaults
        if (base !== null) merged = root.deepMerge(merged, base)
        if (host !== null) merged = root.deepMerge(merged, host)
        root.theme = merged.theme
        root.layout = merged.layout
        root.shadow = merged.shadow
        root.font = merged.font
        root.widgets = merged.widgets
        root.valid = true
        root.warnedInvalid = false
    }

    FileView {
        id: baseFile
        path: Quickshell.shellPath("config.json")
        watchChanges: true
        onLoaded: { root.baseText = text(); root.reapply() }
        onFileChanged: { root.baseText = text(); root.reapply() }
        onLoadFailed: err => console.warn(`Config: config.json not loaded: ${FileViewError.toString(err)}`)
    }

    FileView {
        id: hostFile
        path: root.hostname !== "" ? Quickshell.shellPath(`config.${root.hostname}.json`) : ""
        watchChanges: true
        onLoaded: { root.hostText = text(); root.reapply() }
        onFileChanged: { root.hostText = text(); root.reapply() }
        onLoadFailed: () => {} // host file is optional
    }

    FileView {
        id: hostnameFile
        path: "/etc/hostname"
        watchChanges: false
        onLoaded: {
            root.hostname = text().trim()
            hostFile.path = Quickshell.shellPath(`config.${root.hostname}.json`)
        }
        onLoadFailed: () => {} // no hostname -> base config only
    }
}
