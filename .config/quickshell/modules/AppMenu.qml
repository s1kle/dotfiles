import Quickshell
import Quickshell.Io
import QtQuick

import qs.services
import qs.components
import "scripts/search.js" as Search

// Radial app launcher: center Search + up to 8 filtered results flung to compass
// slots with spokes. Up/Down cycle results (from top, looped); Enter launches.
// Toggle via IPC: qs -p <shell.qml> ipc call appmenu toggle
PanelWindow {
    id: win

    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    focusable: true
    exclusiveZone: 0

    property var results: win.filterApps(search.text)
    property int selected: 0

    readonly property int ringR: 220
    readonly property int ringD: 156
    // Fill/priority order: top, top-right, top-left, right, left, br, bl, bottom.
    readonly property var slots: [
        Qt.point(0, -win.ringR),        // 1 top
        Qt.point(win.ringD, -win.ringD),// 2 top-right
        Qt.point(-win.ringD, -win.ringD),// 3 top-left
        Qt.point(win.ringR, 0),         // 4 right
        Qt.point(-win.ringR, 0),        // 5 left
        Qt.point(win.ringD, win.ringD), // 6 bottom-right
        Qt.point(-win.ringD, win.ringD),// 7 bottom-left
        Qt.point(0, win.ringR)          // 8 bottom
    ]

    function filterApps(q: string): var {
        return Search.rank(Apps.list, q, a => a.name)
    }

    function open(): void { win.visible = true; search.input.forceActiveFocus() }
    function close(): void { search.text = ""; win.visible = false }
    function toggle(): void { win.visible ? win.close() : win.open() }
    function launchSelected(): void {
        const a = win.results[win.selected]
        if (a) { Apps.launch(a); win.close() }
    }

    onResultsChanged: win.selected = 0 // start from the top entry

    IpcHandler {
        target: "appmenu"
        function toggle(): void { win.toggle() }
        function open(): void { win.open() }
        function close(): void { win.close() }
    }

    // Radial mouse selection: the screen is 8 × 45° sectors around the center.
    // Hovering a sector selects its entry (accent border); clicking it launches;
    // clicking the empty center/sector closes.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        readonly property int deadZone: 100

        function sectorAt(mx: real, my: real): int {
            const dx = mx - win.width / 2
            const dy = my - win.height / 2
            if (Math.hypot(dx, dy) < deadZone)
                return -1
            const ang = Math.atan2(dy, dx)
            let best = -1
            let bestDiff = Infinity
            for (let i = 0; i < 8; i++) {
                const s = win.slots[i]
                let d = Math.abs(ang - Math.atan2(s.y, s.x))
                if (d > Math.PI)
                    d = 2 * Math.PI - d
                if (d < bestDiff) {
                    bestDiff = d
                    best = i
                }
            }
            return win.results[best] != null ? best : -1
        }

        onPositionChanged: e => {
            const idx = sectorAt(e.x, e.y)
            if (idx >= 0)
                win.selected = idx
        }
        onClicked: e => {
            const idx = sectorAt(e.x, e.y)
            if (idx >= 0) {
                Apps.launch(win.results[idx])
                win.close()
            } else {
                win.close()
            }
        }
    }

    // spokes (behind entries)
    Repeater {
        model: 8
        delegate: Rectangle {
            required property int index
            readonly property var app: win.results[index] ?? null
            readonly property point off: win.slots[index]

            height: 2
            width: app ? Math.hypot(off.x, off.y) : 0
            color: Theme.accentMuted
            antialiasing: true
            x: win.width / 2
            y: win.height / 2 - 1
            transformOrigin: Item.Left
            rotation: Math.atan2(off.y, off.x) * 180 / Math.PI
            opacity: app ? 1 : 0

            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    // entries
    Repeater {
        model: 8
        delegate: Entry {
            id: cell
            required property int index
            readonly property var app: win.results[index] ?? null

            visible: opacity > 0
            name: app ? app.name : ""
            icon: app ? app.icon : null
            selected: index === win.selected && app !== null

            x: win.width / 2 - width / 2 + (app ? win.slots[index].x : 0)
            y: win.height / 2 - height / 2 + (app ? win.slots[index].y : 0)
            opacity: app ? 1 : 0
            scale: app ? 1 : 0.5

            Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        }
    }

    Search {
        id: search
        placeholder: "APP"
        anchors.centerIn: parent
        onNavigate: d => {
            if (win.results.length > 0)
                win.selected = (win.selected + d + win.results.length) % win.results.length
        }
        onAccepted: win.launchSelected()
        onCancelled: win.close()
    }
}
