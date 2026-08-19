import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import qs.services
import qs.widgets
import qs.components
import "sidebar"
import "scripts/sidebar-layout.js" as Packer

// Right-edge hover sidebar (primary screen only). A `trigger`-px invisible zone
// on the screen edge springs the rail open; it collapses after an idle delay
// once neither the zone nor the rail is hovered (single refreshHover rule, same
// as TopBar). Config-driven tile order/size via the row-packer; keyboard focus
// is grabbed on open for arrow/PgUp-PgDn/Enter/Esc over the interactive tiles.
PanelWindow {
    id: win

    screen: Quickshell.screens[1]
    visible: Config.sidebar.enabled
    color: "transparent"
    anchors { top: true; right: true; bottom: true }
    // rail width + a little transparent room on the left so the tiles' drop
    // shadow (offset/blur to the left) isn't clipped at the window edge.
    readonly property int shadowMargin: 40
    implicitWidth: Config.sidebar.width + shadowMargin
    // Ignore other surfaces' exclusive zones (e.g. the TopBar) so the rail spans
    // from the very top of the screen. NB: setting exclusiveZone here would force
    // the mode back to Normal, so we don't — Ignore reserves nothing anyway.
    exclusionMode: ExclusionMode.Ignore

    // grab keyboard only while open, so normal typing isn't intercepted.
    WlrLayershell.keyboardFocus: win.expanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool expanded: false
    property int selIndex: -1
    property var tiles: [] // interactive RailButtons, in creation (rail) order
    // keep tiles built through the slide-out so they animate away with the rail
    // (not destroyed instantly); dropped once off-screen.
    property bool railLive: false

    // fixed 100 Mbit/s ceiling for the net rings.
    readonly property real netMax: 12.5 * 1024 * 1024
    readonly property bool hasMusic: Mpris.activePlayer !== null

    // full rail width per row (no horizontal padding — tiles/cards bleed to the
    // rail edges); only a vertical margin is applied on the ColumnLayout.
    readonly property real railInner: Config.sidebar.width
    readonly property real unit: (railInner - (Config.sidebar.columns - 1) * Config.sidebar.gap) / Config.sidebar.columns

    // union the edge trigger zone + the rail; the transparent gap passes clicks through.
    mask: Region {
        item: triggerZone
        Region { item: rail }
    }

    function refreshHover() {
        if (zoneHover.hovered || railHover.hovered) { collapseTimer.stop(); win.expanded = true }
        else collapseTimer.restart()
    }

    function weatherSlot(s) {
        return s ? ({ temp: s.temp, icon: Quickshell.shellPath("assets/weather/" + Weather.iconFor(s.code) + ".svg") }) : null
    }

    // interactive-tile registry for keyboard nav; reassigning fires tilesChanged
    // so `selected` bindings re-evaluate (in-place array mutation doesn't notify).
    function register(t) { const a = win.tiles.slice(); a.push(t); win.tiles = a }
    function unregister(t) { const a = win.tiles.slice(); const i = a.indexOf(t); if (i >= 0) { a.splice(i, 1); win.tiles = a } }
    // fire-and-forget IPC toggle to a sibling radial menu (PowerMenu/AppMenu/ClipboardMenu).
    function ipcCall(target) { ipcProc.exec(["qs", "ipc", "call", target, "toggle"]) }
    function stepSelected(dir) { const t = win.tiles[win.selIndex]; if (t && t.scrollable) dir > 0 ? t.stepUp() : t.stepDown() }
    function activateSelected() { const t = win.tiles[win.selIndex]; if (t) t.activated() }

    function tileFor(cell) {
        if (cell.type === "divider") return dividerC
        switch (cell.id) {
            case "clock":        return clockC
            case "calendar":     return calendarC
            case "workspaces":   return workspacesC
            case "music":        return musicC
            case "tray":         return trayC
            case "weather":      return weatherC
            case "cpu": case "mem": case "disk":
            case "download": case "upload": case "battery":
            case "gpu": case "temp": return gaugeC
            case "uptime": return textC
            case "hyprlayout": return textC
            case "volume": case "brightness": case "mic":
            case "network": case "bluetooth": case "vpn": case "nightlight": case "notifications":
            case "power": case "appmenu": case "screenshot": case "clipboard": case "updates": case "recording": return buttonC
            default:
                console.warn("Sidebar: unknown item id", cell.id)
                return null
        }
    }

    onExpandedChanged: {
        if (win.expanded) { railHideTimer.stop(); win.railLive = true }
        else { win.selIndex = -1; railHideTimer.restart() }
    }
    // outlives the 300ms slide-out, then drops the tiles.
    Timer { id: railHideTimer; interval: 340; onTriggered: win.railLive = false }

    Item {
        id: triggerZone
        anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
        width: Config.sidebar.trigger
        HoverHandler { id: zoneHover; onHoveredChanged: win.refreshHover() }
    }

    Rectangle {
        id: rail
        anchors { top: parent.top; bottom: parent.bottom }
        width: Config.sidebar.width
        x: win.expanded ? parent.width - width : parent.width // slide in from the edge
        color: "transparent" // tiles/cards float over the desktop

        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        HoverHandler { id: railHover; onHoveredChanged: win.refreshHover() }

        focus: win.expanded
        Keys.onPressed: event => {
            const n = win.tiles.length
            if (event.key === Qt.Key_Escape) {
                win.expanded = false
                event.accepted = true
            } else if (event.key === Qt.Key_Down) {
                win.selIndex = Math.min(n - 1, win.selIndex + 1); event.accepted = true
            } else if (event.key === Qt.Key_Up) {
                win.selIndex = Math.max(0, win.selIndex - 1); event.accepted = true
            } else if (event.key === Qt.Key_PageUp) {
                win.stepSelected(1); event.accepted = true
            } else if (event.key === Qt.Key_PageDown) {
                win.stepSelected(-1); event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                win.activateSelected(); event.accepted = true
            }
        }

        // Only build the (effect-heavy) tiles while open. Collapsed, the rail is
        // a bare rectangle off-screen — no MultiEffect/Shape work runs, so the
        // idle shell stays cheap (this was making ThemeMenu janky). Vertical
        // margin only; tiles/cards bleed to the rail edges horizontally.
        Loader {
            active: win.railLive
            anchors.fill: parent
            anchors.topMargin: 8
            anchors.bottomMargin: 8
            sourceComponent: railColumnC
        }

    }

    Timer { id: collapseTimer; interval: Config.sidebar.collapseDelay; onTriggered: win.expanded = false }
    Process { id: ipcProc }

    // pause the heavy stats poll while the rail is closed (nothing shows it).
    Binding { target: SystemUsage; property: "active"; value: win.expanded }

    // short "volume change" blip so you hear the new level while adjusting.
    // Needs libcanberra (canberra-gtk-play); fails silently if absent.
    Process { id: volumeSound }
    function volumeBlip() { volumeSound.exec(["canberra-gtk-play", "-i", "audio-volume-change"]) }

    // ── tile components (read `parent.cell` from their Loader) ──

    Component {
        id: railColumnC
        ColumnLayout {
            spacing: Config.sidebar.gap

            Repeater {
                model: Packer.packRows(Config.sidebar.items, Config.sidebar.columns)
                delegate: Item {
                    id: rowItem
                    required property var modelData // { cells: [...] }
                    readonly property var cells: modelData.cells
                    readonly property bool isSpacer: cells.length === 1 && cells[0].type === "spacer"
                    Layout.fillWidth: true
                    Layout.fillHeight: isSpacer // absorbs slack, pushing later rows down
                    implicitHeight: isSpacer ? 0 : rowFlow.implicitHeight

                    Row {
                        id: rowFlow
                        visible: !rowItem.isSpacer
                        width: win.railInner
                        spacing: Config.sidebar.gap

                        Repeater {
                            model: rowItem.isSpacer ? [] : rowItem.cells
                            delegate: Loader {
                                required property var modelData // a cell { id?, type?, size, cols }
                                readonly property var cell: modelData
                                width: cell.cols * win.unit + (cell.cols - 1) * Config.sidebar.gap
                                sourceComponent: win.tileFor(cell)
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: dividerC
        Item {
            height: 9
            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 12
                height: 1
                color: Theme.accentMuted
            }
        }
    }

    Component {
        id: gaugeC
        RailGauge {
            property var cell: parent ? parent.cell : ({ cols: 1 })
            cols: cell.cols
            label: ({ cpu: "CPU", mem: "RAM", disk: "SSD", download: "↓", upload: "↑", battery: "BAT", gpu: "GPU", temp: "TMP" })[cell.id] ?? ""
            value: {
                switch (cell.id) {
                    case "cpu": return SystemUsage.cpuPerc / 100
                    case "mem": return SystemUsage.memPerc / 100
                    case "disk": return SystemUsage.diskPerc / 100
                    case "battery": return Battery.available ? Battery.percentage / 100 : 0
                    case "download": return Math.min(1, SystemUsage.downloadSpeed / win.netMax)
                    case "upload": return Math.min(1, SystemUsage.uploadSpeed / win.netMax)
                    case "gpu": return SystemUsage.hasGpu ? SystemUsage.gpuUsage / 100 : 0
                    // ponytail: naive fixed-100C ceiling, not a real throttle point —
                    // fine for "roughly how hot", adjust if it reads misleadingly full/empty
                    case "temp": return Math.min(1, SystemUsage.cpuTemp / 100)
                }
                return 0
            }
        }
    }

    Component {
        id: textC
        RailTile {
            id: tile
            property var cell: parent ? parent.cell : ({ cols: 1 })
            cols: cell.cols
            Text {
                anchors.centerIn: parent
                text: {
                    switch (cell.id) {
                        case "uptime": return SystemUsage.uptime
                        case "hyprlayout": return Hyprland.tilingLayout === "master" ? "M" : "D"
                    }
                    return ""
                }
                color: tile.hovered ? Theme.text : Theme.textDim
                font.family: Config.font.family
                font.pixelSize: 12
            }
            TapHandler {
                enabled: cell.id === "hyprlayout"
                onTapped: Hyprland.toggleLayout()
            }
        }
    }

    Component {
        id: buttonC
        RailButtonTile { sidebarWin: win }
    }

    Component {
        id: clockC
        RailCard {
            property var cell: parent ? parent.cell : ({ cols: 4 })
            cols: cell.cols
            Column {
                width: parent.width
                spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Time.clockTime
                    color: Theme.text
                    font.family: Config.font.family
                    font.pixelSize: 22
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Time.longDate
                    color: Theme.textDim
                    font.family: Config.font.family
                    font.pixelSize: 10
                }
            }
        }
    }

    Component {
        id: calendarC
        RailCard {
            property var cell: parent ? parent.cell : ({ cols: 4 })
            cols: cell.cols
            CalendarWidget {}
        }
    }

    Component {
        id: workspacesC
        RailWorkspacesTile {}
    }

    Component {
        id: musicC
        RailMusicTile { sidebarWin: win }
    }

    Component {
        id: trayC
        RailTrayTile { sidebarWin: win }
    }

    Component {
        id: weatherC
        RailCard {
            property var cell: parent ? parent.cell : ({ cols: 4 })
            cols: cell.cols
            WeatherWidget {
                anchors.horizontalCenter: parent.horizontalCenter
                morning: win.weatherSlot(Weather.morning)
                now: win.weatherSlot(Weather.now)
                evening: win.weatherSlot(Weather.evening)
            }
        }
    }
}
