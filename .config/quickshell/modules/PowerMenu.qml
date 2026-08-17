import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects

import qs.services
import qs.components

// Radial power menu: Lock / Suspend / Logout / Reboot / Shutdown, evenly
// spaced on one ring (same shape as ThemeMenu/AppMenu). Reboot/Shutdown need
// a second click/Enter on the same entry within 3s ("armed") before running;
// everything else fires immediately. IPC: qs ipc call powermenu toggle
PanelWindow {
    id: win

    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    focusable: true
    exclusiveZone: 0

    readonly property var actions: [
        { id: "lock",     label: "Lock",     icon: "lock",    destructive: false },
        { id: "suspend",  label: "Suspend",  icon: "suspend", destructive: false },
        { id: "logout",   label: "Logout",   icon: "logout",  destructive: false },
        { id: "reboot",   label: "Reboot",   icon: "restart", destructive: true },
        { id: "shutdown", label: "Shutdown", icon: "power",   destructive: true },
    ]

    property int selected: 0
    property bool fanned: false
    property string armedId: ""

    readonly property int ringR: 200
    readonly property var slots: {
        const out = []
        for (let i = 0; i < win.actions.length; i++) {
            const ang = -Math.PI / 2 + i * (2 * Math.PI / win.actions.length)
            out.push(Qt.point(win.ringR * Math.cos(ang), win.ringR * Math.sin(ang)))
        }
        return out
    }

    function open(): void {
        win.visible = true
        win.fanned = false
        win.selected = 0
        win.armedId = ""
        fanTimer.restart()
    }
    function close(): void { win.fanned = false; win.visible = false; win.armedId = "" }
    function toggle(): void { win.visible ? win.close() : win.open() }

    Timer { id: fanTimer; interval: 32; onTriggered: win.fanned = true }
    Timer { id: armTimer; interval: 3000; onTriggered: win.armedId = "" }

    function run(id: string): void {
        switch (id) {
            case "lock": Quickshell.execDetached(["hyprlock"]); break
            case "suspend": Quickshell.execDetached(["systemctl", "suspend"]); break
            // Hyprland 0.55+ moved dispatchers behind its Lua eval layer;
            // plain "exit" is a no-op there. hl.dsp.exit() is the current form.
            case "logout": Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"]); break
            case "reboot": Quickshell.execDetached(["systemctl", "reboot"]); break
            case "shutdown": Quickshell.execDetached(["systemctl", "poweroff"]); break
        }
    }

    function activate(idx: int): void {
        const a = win.actions[idx]
        if (!a) return
        if (a.destructive && win.armedId !== a.id) {
            win.armedId = a.id
            armTimer.restart()
            return
        }
        win.run(a.id)
        win.close()
    }

    IpcHandler {
        target: "powermenu"
        function toggle(): void { win.toggle() }
        function open(): void { win.open() }
        function close(): void { win.close() }
    }

    Item {
        id: catcher
        anchors.fill: parent
        focus: win.visible
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) { win.close(); event.accepted = true }
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                win.selected = (win.selected + 1) % win.actions.length
                if (win.armedId !== "" && win.armedId !== win.actions[win.selected].id) win.armedId = ""
                event.accepted = true
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                win.selected = (win.selected - 1 + win.actions.length) % win.actions.length
                if (win.armedId !== "" && win.armedId !== win.actions[win.selected].id) win.armedId = ""
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                win.activate(win.selected); event.accepted = true
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        readonly property int deadZone: 90

        function sectorAt(mx: real, my: real): int {
            const dx = mx - win.width / 2
            const dy = my - win.height / 2
            if (Math.hypot(dx, dy) < deadZone) return -1
            const ang = Math.atan2(dy, dx)
            let best = 0, bestDiff = Infinity
            for (let i = 0; i < win.slots.length; i++) {
                const s = win.slots[i]
                let d = Math.abs(ang - Math.atan2(s.y, s.x))
                if (d > Math.PI) d = 2 * Math.PI - d
                if (d < bestDiff) { bestDiff = d; best = i }
            }
            return best
        }

        onPositionChanged: e => {
            const idx = sectorAt(e.x, e.y)
            if (idx >= 0) {
                if (win.armedId !== "" && win.armedId !== win.actions[idx].id) win.armedId = ""
                win.selected = idx
            }
        }
        onClicked: e => {
            const idx = sectorAt(e.x, e.y)
            if (idx >= 0) win.activate(idx)
            else win.close()
        }
    }

    Repeater {
        model: win.actions.length
        delegate: Rectangle {
            required property int index
            readonly property point off: win.slots[index]
            height: 2
            width: win.fanned ? Math.hypot(off.x, off.y) : 0
            color: Theme.accentMuted
            antialiasing: true
            x: win.width / 2
            y: win.height / 2 - 1
            transformOrigin: Item.Left
            rotation: Math.atan2(off.y, off.x) * 180 / Math.PI
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }
    }

    Repeater {
        model: win.actions.length
        delegate: PowerEntry {
            id: cell
            required property int index
            readonly property var a: win.actions[index]
            label: a.label
            iconName: a.icon
            selected: index === win.selected
            armed: win.armedId === a.id
            x: win.width / 2 - width / 2 + (win.fanned ? win.slots[index].x : 0)
            y: win.height / 2 - height / 2 + (win.fanned ? win.slots[index].y : 0)
            Behavior on x { enabled: win.fanned; NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on y { enabled: win.fanned; NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        }
    }

    // center label, same shell as Search but static text — sits inside the
    // MouseArea's dead zone so it never intercepts sector clicks.
    Rectangle {
        anchors.centerIn: parent
        implicitWidth: label.implicitWidth + 32
        implicitHeight: 48
        radius: 14
        color: Theme.surface

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#80000000"
            blurMax: 24
            shadowBlur: 1.0
            shadowHorizontalOffset: -12
            shadowVerticalOffset: 12
        }

        Text {
            id: label
            anchors.centerIn: parent
            text: "Power Menu"
            color: Theme.text
            font.family: Config.font.family
            font.pixelSize: 14
            font.letterSpacing: 14 * 0.12
            font.capitalization: Font.AllUppercase
        }
    }
}
