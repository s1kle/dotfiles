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
    property var defaults: ({
        theme: { name: "Nord" },
        layout: { radius: 12, margin: 6 },
        font: { family: "Annotation Mono" },
        weather: { city: "Primorsky Krai, Nakhodka", refreshMinutes: 15 },
        progress: { size: 66, width: 8 },
        // TopBar expanded rack, in order. `music` auto-hides when no player.
        topbar: { collapseDelay: 0, widgets: ["clock", "weather", "music"] },
        sidebar: {
            enabled: true,
            width: 210,
            trigger: 100,
            // keeps the edge-hover strip off the top corner, where a maximized
            // window's own titlebar buttons (close/maximize) usually sit --
            // otherwise the strip (full monitor height by default) eats clicks
            // meant for those buttons even while the rail is collapsed.
            triggerTopMargin: 48,
            tileSize: 42,
            gap: 6,
            columns: 4,
            scrollStep: 0.05,
            // accumulated wheel/touchpad delta needed per step (higher = less
            // sensitive; a mouse notch is ~120). scrollInvert mirrors direction.
            scrollThreshold: 120,
            scrollInvert: false,
            collapseDelay: 250,
            // base set for every host; hosts (e.g. config.laptop.json) replace this
            // whole list to add hardware items like wifi/bluetooth/battery.
            items: [
                { id: "clock",      size: "wide" },
                { id: "calendar",   size: "wide" },
                { id: "workspaces", size: "wide" },
                { id: "weather",    size: "wide" },
                { id: "music",      size: "wide" },
                { type: "divider" },
                { id: "hyprlayout", size: "small" },
                { type: "divider" },
                { id: "volume", size: "small" }, { id: "brightness", size: "small" },
                { id: "mic",    size: "small" }, { id: "notifications", size: "small" },
                { id: "appmenu", size: "small" },
                { id: "screenshot", size: "small" },
                { id: "clipboard", size: "small" },
                { type: "divider" },
                { id: "cpu",  size: "small" }, { id: "mem", size: "small" },
                { id: "disk", size: "small" }, { id: "download", size: "small" },
                { id: "upload", size: "small" },
                { id: "temp", size: "small" }, { id: "uptime", size: "wide" },
                { id: "updates", size: "small" },
                { type: "spacer" },
                { id: "power", size: "wide" }
            ]
        },
    })

    property var theme: defaults.theme
    property var layout: defaults.layout
    property var font: defaults.font
    property var weather: defaults.weather
    property var progress: defaults.progress
    property var topbar: defaults.topbar
    property var sidebar: defaults.sidebar

    property var baseJson: null // last-good parsed base config
    property var hostJson: null // last-good parsed host config
    property bool warnedInvalid: false

    function parseJson(text: string): var {
        if (text === "") return undefined
        try {
            return JSON.parse(text)
        } catch (e) {
            if (!root.warnedInvalid) {
                console.warn(`Config: invalid JSON, keeping last good state: ${e?.message ?? e}`)
                root.warnedInvalid = true
            }
            return undefined
        }
    }

    // Merge driven by base keys: override keys absent from base are ignored,
    // objects recurse, scalars are replaced wholesale. Arrays replace wholesale
    // (so a host can supply a completely different widget list, not an
    // index-by-index merge).
    function deepMerge(base: var, override: var): var {
        if (override === undefined || override === null) return base
        if (Array.isArray(base) || Array.isArray(override)) return override
        if (typeof base !== "object" || typeof override !== "object") return override
        const out = {}
        for (const key of Object.keys(base)) {
            out[key] = root.deepMerge(base[key], override[key])
        }
        return out
    }

    // Per-file last-good: a failed parse leaves that file's previous parsed
    // state in place, so one broken file never reverts its keys to defaults.
    function onBaseText(text: string): void {
        const parsed = root.parseJson(text)
        if (parsed !== undefined) root.baseJson = parsed
        root.reapply()
    }

    function onHostText(text: string): void {
        const parsed = root.parseJson(text)
        if (parsed !== undefined) root.hostJson = parsed
        root.reapply()
    }

    function reapply(): void {
        if (root.baseJson === null && root.hostJson === null) return // nothing loaded yet
        let merged = root.defaults
        if (root.baseJson !== null) merged = root.deepMerge(merged, root.baseJson)
        if (root.hostJson !== null) merged = root.deepMerge(merged, root.hostJson)
        root.theme = merged.theme
        root.layout = merged.layout
        root.font = merged.font
        root.weather = merged.weather
        root.progress = merged.progress
        root.topbar = merged.topbar
        root.sidebar = merged.sidebar
        root.valid = true
        root.warnedInvalid = false
    }

    FileView {
        id: baseFile
        path: Quickshell.shellPath("config.json")
        watchChanges: true
        onLoaded: { root.onBaseText(text()) }
        onFileChanged: baseFile.reload() // reload re-reads then fires onLoaded with fresh text
        onLoadFailed: err => console.warn(`Config: config.json not loaded: ${FileViewError.toString(err)}`)
    }

    FileView {
        id: hostFile
        path: root.hostname !== "" ? Quickshell.shellPath(`config.${root.hostname}.json`) : ""
        watchChanges: true
        onLoaded: { root.onHostText(text()) }
        onFileChanged: hostFile.reload() // reload re-reads then fires onLoaded with fresh text
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
