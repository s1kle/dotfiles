import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

import qs.services
import qs.widgets
import qs.components
import "scripts/sidebar-layout.js" as Packer

// Right-edge hover sidebar (primary screen only). A `trigger`-px invisible zone
// on the screen edge springs the rail open; it collapses after an idle delay
// once neither the zone nor the rail is hovered (single refreshHover rule, same
// as TopBar). Config-driven tile order/size via the row-packer; keyboard focus
// is grabbed on open for arrow/PgUp-PgDn/Enter/Esc over the interactive tiles.
PanelWindow {
    id: win

    screen: Quickshell.screens[0]
    visible: Config.sidebar.enabled
    color: "transparent"
    anchors { top: true; right: true; bottom: true }
    // rail width + a transparent left margin so left-anchored flyouts have room
    // to render without clipping at the window edge.
    readonly property int flyoutSpace: 360
    implicitWidth: Config.sidebar.width + flyoutSpace
    exclusiveZone: 0

    // grab keyboard only while open, so normal typing isn't intercepted.
    WlrLayershell.keyboardFocus: win.expanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool expanded: false
    property int selIndex: -1
    property var tiles: [] // interactive RailButtons, in creation (rail) order

    // fixed 100 Mbit/s ceiling for the net rings (copied from Bar.qml).
    readonly property real netMax: 12.5 * 1024 * 1024
    property real musicPos: 0
    readonly property bool hasMusic: Mpris.activePlayer !== null

    // per-column unit width inside the rail (margins 8 each side).
    readonly property real railInner: Config.sidebar.width - 16
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
    function stepSelected(dir) { const t = win.tiles[win.selIndex]; if (t && t.scrollable) dir > 0 ? t.stepUp() : t.stepDown() }
    function activateSelected() { const t = win.tiles[win.selIndex]; if (t) t.activated() }

    function tileFor(cell) {
        if (cell.type === "divider") return dividerC
        switch (cell.id) {
            case "clock":        return clockC
            case "workspaces":   return workspacesC
            case "music":        return musicC
            case "weather":      return weatherC
            case "cpu": case "mem": case "disk":
            case "download": case "upload": case "battery": return gaugeC
            case "volume": case "brightness": case "mic":
            case "network": case "bluetooth": case "notifications":
            case "power":        return buttonC
            default:
                console.warn("Sidebar: unknown item id", cell.id)
                return null
        }
    }

    onExpandedChanged: if (!win.expanded) { win.selIndex = -1; stub.visible = false }

    // v1 left-click config: a minimal SliderPanel over a dim scrim. Real device/
    // wifi/bluetooth/power pickers are a deferred follow-up spec.
    // ponytail: single shared modal stub; build the real per-service pickers later.
    function openStub(title, value, sink) {
        stub.title = title
        stub.value = value
        stub.sink = sink
        stub.visible = true
    }

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
        color: Theme.background

        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        HoverHandler { id: railHover; onHoveredChanged: win.refreshHover() }

        focus: win.expanded
        Keys.onPressed: event => {
            const n = win.tiles.length
            if (event.key === Qt.Key_Escape) {
                if (stub.visible) stub.visible = false; else win.expanded = false
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

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
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

        // ── dim scrim + config stub ──
        Rectangle {
            id: stub
            anchors.fill: parent
            visible: false
            color: "#99000000"
            property string title: ""
            property real value: 0
            property var sink: null

            MouseArea { anchors.fill: parent; onClicked: stub.visible = false }

            SliderPanel {
                anchors.centerIn: parent
                title: stub.title
                value: stub.value
                onMoved: v => { stub.value = v; if (stub.sink) stub.sink(v) }
            }
        }
    }

    Timer { id: collapseTimer; interval: Config.sidebar.collapseDelay; onTriggered: win.expanded = false }

    // poll music position while the rail is open (mirrors TopBar).
    Timer {
        interval: 1000
        running: win.expanded && win.hasMusic
        repeat: true
        triggeredOnStart: true
        onTriggered: win.musicPos = Mpris.activePlayer ? Mpris.activePlayer.position : 0
    }
    Connections {
        target: Mpris.activePlayer
        function onTrackTitleChanged() { win.musicPos = 0 }
    }

    // ── tile components (read `parent.cell` from their Loader) ──

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
            label: ({ cpu: "CPU", mem: "RAM", disk: "SSD", download: "↓", upload: "↑", battery: "BAT" })[cell.id] ?? ""
            value: {
                switch (cell.id) {
                    case "cpu": return SystemUsage.cpuPerc / 100
                    case "mem": return SystemUsage.memPerc / 100
                    case "disk": return SystemUsage.diskPerc / 100
                    case "battery": return Battery.available ? Battery.percentage / 100 : 0
                    case "download": return Math.min(1, SystemUsage.downloadSpeed / win.netMax)
                    case "upload": return Math.min(1, SystemUsage.uploadSpeed / win.netMax)
                }
                return 0
            }
            detail: label + " · " + Math.round(value * 100) + "%"
        }
    }

    Component {
        id: buttonC
        RailButton {
            id: btn
            property var cell: parent ? parent.cell : ({ cols: 1 })
            cols: cell.cols
            iconName: ({ volume: "volume", brightness: "brightness", mic: "mic", network: "wifi", bluetooth: "bluetooth", notifications: "bell", power: "power" })[cell.id] ?? ""
            label: ({ volume: "Vol", brightness: "Bri", mic: "Mic" })[cell.id] ?? ""
            danger: cell.id === "power"
            showSlider: cell.id === "volume" || cell.id === "brightness" || cell.id === "mic"
            scrollable: showSlider
            selected: win.selIndex >= 0 && win.tiles[win.selIndex] === btn
            value: {
                switch (cell.id) {
                    case "volume": return Audio.volume
                    case "brightness": return Brightness.value
                    case "mic": return Audio.sourceVolume
                }
                return 0
            }
            detail: {
                switch (cell.id) {
                    case "network": return "Wi-Fi · " + (Network.wifiEnabled ? (Network.wifiSsid || "on") : "off")
                    case "bluetooth": return "Bluetooth · " + (Bluetooth.enabled ? Bluetooth.connectedCount + " connected" : "off")
                    case "notifications": return "Notifications · " + NotificationService.list.length
                    case "power": return "Power menu"
                }
                return ""
            }
            onMoved: v => {
                if (cell.id === "volume") Audio.setVolume(v)
                else if (cell.id === "brightness") Brightness.set(v)
                else if (cell.id === "mic") Audio.setSourceVolume(v)
            }
            onToggled: {
                if (cell.id === "volume") Audio.toggleMuted()
                else if (cell.id === "mic") Audio.setSourceVolume(0)
                else if (cell.id === "network") Network.setWifiEnabled(!Network.wifiEnabled)
                else if (cell.id === "bluetooth") Bluetooth.setEnabled(!Bluetooth.enabled)
            }
            onActivated: {
                if (showSlider) win.openStub(label, value, v => btn.moved(v))
            }
            Component.onCompleted: win.register(btn)
            Component.onDestruction: win.unregister(btn)
        }
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
        id: workspacesC
        RailCard {
            property var cell: parent ? parent.cell : ({ cols: 4 })
            cols: cell.cols
            // dots on the left, focused monitor name on the right (space-between).
            Item {
                width: parent.width
                height: 16

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Repeater {
                        model: Hyprland.workspaces
                        delegate: Rectangle {
                            required property var modelData
                            width: 14; height: 14; radius: 7
                            color: modelData.active ? Theme.accent : (modelData.occupied ? Theme.textDim : "transparent")
                            border.width: modelData.occupied || modelData.active ? 0 : 2
                            border.color: Theme.accentMuted
                            TapHandler { onTapped: Hyprland.switchTo(modelData.id) }
                        }
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Hyprland.monitorName
                    color: Theme.textDim
                    font.family: Config.font.family
                    font.pixelSize: 11
                }
            }
        }
    }

    Component {
        id: musicC
        RailCard {
            property var cell: parent ? parent.cell : ({ cols: 4 })
            cols: cell.cols
            // vertical card (fits the narrow rail); ":(" placeholder when idle.
            Item {
                width: parent.width
                height: win.hasMusic ? full.implicitHeight : 64

                Text {
                    visible: !win.hasMusic
                    anchors.centerIn: parent
                    text: ":("
                    color: Theme.textDim
                    font.family: Config.font.family
                    font.pixelSize: 26
                }

                Column {
                    id: full
                    visible: win.hasMusic
                    width: parent.width
                    spacing: 6

                    ClippingRectangle {
                        width: parent.width
                        height: 110
                        radius: 12
                        color: "transparent"
                        Rectangle {
                            anchors.fill: parent
                            visible: !cover.visible
                            gradient: Gradient {
                                GradientStop { position: 0; color: Theme.accent }
                                GradientStop { position: 1; color: Theme.accentHover }
                            }
                        }
                        Image {
                            id: cover
                            anchors.fill: parent
                            source: Mpris.activePlayer ? Mpris.activePlayer.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: source !== "" && status === Image.Ready
                        }
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: Mpris.activePlayer ? Mpris.activePlayer.trackTitle : ""
                        color: Theme.text
                        font.family: Config.font.family
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: Mpris.activePlayer ? Mpris.activePlayer.trackArtist : ""
                        color: Theme.textDim
                        font.family: Config.font.family
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10
                        Button { text: "Prev"; fontSize: 11; hpad: 7; textColor: Theme.textDim; enabled: Mpris.canGoPrevious; onClicked: Mpris.previous() }
                        Button { text: Mpris.isPlaying ? "Pause" : "Play"; fontSize: 11; hpad: 7; textColor: Theme.text; onClicked: Mpris.togglePlaying() }
                        Button { text: "Next"; fontSize: 11; hpad: 7; textColor: Theme.textDim; enabled: Mpris.canGoNext; onClicked: Mpris.next() }
                    }

                    ProgressBar {
                        width: parent.width
                        value: {
                            const p = Mpris.activePlayer
                            return p && p.length > 0 ? win.musicPos / p.length : 0
                        }
                        seekable: Mpris.activePlayer ? Mpris.activePlayer.canSeek : false
                        onSeek: frac => {
                            const p = Mpris.activePlayer
                            if (p && p.canSeek) { p.position = frac * p.length; win.musicPos = frac * p.length }
                        }
                    }
                }
            }
        }
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
