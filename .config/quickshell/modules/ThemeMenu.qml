import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Window

import qs.services
import qs.components
import "scripts/search.js" as Search

// Radial theme switcher: opens prefilled with the current theme's variant alias
// (@dark / @light). Hover/arrow selects and LIVE-PREVIEWS; Enter/click commits
// to config.json; Esc/click-away reverts. IPC: qs ipc call thememenu toggle
PanelWindow {
    id: win

    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    focusable: true
    exclusiveZone: 0

    property var results: win.filterThemes(search.text)
    property int selected: 0

    readonly property int ringR: 240
    readonly property int ringD: 170
    readonly property var slots: [
        Qt.point(0, -win.ringR),
        Qt.point(win.ringD, -win.ringD),
        Qt.point(-win.ringD, -win.ringD),
        Qt.point(win.ringR, 0),
        Qt.point(-win.ringR, 0),
        Qt.point(win.ringD, win.ringD),
        Qt.point(-win.ringD, win.ringD),
        Qt.point(0, win.ringR)
    ]

    function currentVariant(): string {
        for (const t of Themes.list)
            if (t.name === Config.theme.name)
                return t.variant
        return "dark"
    }

    // "@dark"/"@light" [name] | "" -> all | name -> ranked all
    function filterThemes(q: string): var {
        const raw = (q || "").trim()
        const m = raw.match(/^@(dark|light)\b\s*(.*)$/i)
        if (m) {
            const variant = m[1].toLowerCase()
            const rest = m[2].trim()
            const subset = Themes.list.filter(t => t.variant === variant)
            if (rest === "")
                return subset.slice(0, 8)
            return Search.rank(subset, rest, t => t.name)
        }
        if (raw === "")
            return Themes.list.slice(0, 8)
        return Search.rank(Themes.list, raw, t => t.name)
    }

    // Preview only tracks selection while the menu is open — otherwise clearing
    // search.text on hide() would recompute results and clobber a just-committed
    // previewName with results[0].
    function preview(): void {
        if (!win.visible) return
        const t = win.results[win.selected]
        Theme.previewName = t ? t.name : ""
    }
    onSelectedChanged: win.preview()
    onResultsChanged: { win.selected = 0; win.preview() }

    function open(): void {
        win.visible = true
        search.text = "@" + win.currentVariant() + " "
        search.input.forceActiveFocus()
        search.input.cursorPosition = search.text.length
    }
    // hide without touching the preview — used after a commit to keep the chosen
    // theme showing while Config's write + hot-reload lands. visible=false first
    // so the search.text reset below can't retrigger preview().
    function hide(): void { win.visible = false; search.text = "" }
    // cancel: revert the live preview, then hide.
    function close(): void { Theme.previewName = ""; win.hide() }
    function toggle(): void { win.visible ? win.close() : win.open() }

    // Once Config's hot-reload catches up to a committed theme, drop the preview
    // so Theme follows the committed Config.theme.name for real (no revert flash).
    Connections {
        target: Config
        function onThemeChanged(): void {
            if (Theme.previewName !== "" && Config.theme.name === Theme.previewName)
                Theme.previewName = ""
        }
    }

    function commit(name: string): void {
        // Merge the chosen theme into the last-good base config and write it back.
        // Pass the JSON as a positional arg to sh (not interpolated into the
        // script) so quotes/newlines/UTF-8 survive verbatim with no encoding step.
        const obj = JSON.parse(JSON.stringify(Config.baseJson || {}))
        obj.theme = obj.theme || {}
        obj.theme.name = name
        const json = JSON.stringify(obj, null, 2) + "\n"
        const path = Quickshell.shellPath("config.json")
        // Atomic temp+rename: a plain `> file` truncate isn't picked up by
        // Config's FileView watcher, but a rename (like rsync) is.
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" > "$2.tmp" && mv "$2.tmp" "$2"', "sh", json, path])
        // Keep the committed theme visible; the Config Connections above clears
        // the preview once the hot-reload catches up.
        Theme.previewName = name
    }
    function commitSelected(): void {
        const t = win.results[win.selected]
        if (t) { win.hide(); win.commit(t.name) }
    }

    IpcHandler {
        target: "thememenu"
        function toggle(): void { win.toggle() }
        function open(): void { win.open() }
        function close(): void { win.close() }
    }

    // Radial mouse selection: 8 × 45° sectors around the center. Hover previews
    // the sector's theme; click commits it; click on the dead zone closes.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        readonly property int deadZone: 110

        function sectorAt(mx: real, my: real): int {
            const dx = mx - win.width / 2
            const dy = my - win.height / 2
            if (Math.hypot(dx, dy) < deadZone)
                return -1
            const ang = Math.atan2(dy, dx)
            let best = -1, bestDiff = Infinity
            for (let i = 0; i < 8; i++) {
                const s = win.slots[i]
                let d = Math.abs(ang - Math.atan2(s.y, s.x))
                if (d > Math.PI) d = 2 * Math.PI - d
                if (d < bestDiff) { bestDiff = d; best = i }
            }
            return win.results[best] != null ? best : -1
        }

        onPositionChanged: e => {
            const idx = sectorAt(e.x, e.y)
            if (idx >= 0) win.selected = idx
        }
        onClicked: e => {
            const idx = sectorAt(e.x, e.y)
            if (idx >= 0) { const nm = win.results[idx].name; win.hide(); win.commit(nm) }
            else win.close()
        }
    }

    // spokes (behind entries)
    Repeater {
        model: 8
        delegate: Rectangle {
            required property int index
            readonly property var t: win.results[index] ?? null
            readonly property point off: win.slots[index]
            height: 2
            width: t ? Math.hypot(off.x, off.y) : 0
            color: Theme.accentMuted
            antialiasing: true
            // Screen (not win.width) so entries are placed correctly from creation
            // — win.width is 0 until the window first maps, which made the entries
            // animate in from the left edge on first open.
            x: Screen.width / 2
            y: Screen.height / 2 - 1
            transformOrigin: Item.Left
            rotation: Math.atan2(off.y, off.x) * 180 / Math.PI
            opacity: t ? 1 : 0
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    // entries
    Repeater {
        model: 8
        delegate: ThemeEntry {
            id: cell
            required property int index
            readonly property var t: win.results[index] ?? null
            visible: opacity > 0
            name: t ? t.name : ""
            palette: t ? t.palette : ({})
            selected: index === win.selected && t !== null
            x: Screen.width / 2 - width / 2 + (t ? win.slots[index].x : 0)
            y: Screen.height / 2 - height / 2 + (t ? win.slots[index].y : 0)
            opacity: t ? 1 : 0
            scale: t ? 1 : 0.5
            Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        }
    }

    Search {
        id: search
        placeholder: "THEME"
        anchors.centerIn: parent
        onNavigate: d => {
            if (win.results.length > 0)
                win.selected = (win.selected + d + win.results.length) % win.results.length
        }
        onAccepted: win.commitSelected()
        onCancelled: win.close()
    }
}
