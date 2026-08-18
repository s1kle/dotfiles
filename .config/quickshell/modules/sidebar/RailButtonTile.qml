import Quickshell
import QtQuick

import qs.services
import qs.widgets

// Scrollable/toggleable rail glyph tile — volume, brightness, mic, network,
// bluetooth, vpn, nightlight, notifications, appmenu, screenshot, clipboard,
// updates, recording, power. Reads `cell.id` to pick icon/value/behavior and
// self-registers with the sidebar window for keyboard nav.
RailButton {
    id: btn
    required property var sidebarWin
    property var cell: parent ? parent.cell : ({ cols: 1 })
    property real prevValue: 0.5 // remembered level for the 0↔previous toggle
    cols: cell.cols

    function applyValue(v) {
        if (cell.id === "volume") { Audio.setVolume(v); sidebarWin.volumeBlip() }
        else if (cell.id === "brightness") Brightness.set(v)
        else if (cell.id === "mic") Audio.setSourceVolume(v)
    }
    iconName: {
        switch (cell.id) {
            case "volume": return (Audio.muted || Audio.volume <= 0) ? "volume-off" : "volume"
            case "mic": return (Audio.sourceMuted || Audio.sourceVolume <= 0) ? "mic-off" : "mic"
            case "network": return Network.wifiEnabled ? "wifi" : "wifi-off"
            case "bluetooth": return Bluetooth.enabled ? "bluetooth" : "bluetooth-off"
            case "vpn": return Vpn.mode === "proxy"
                ? (Vpn.connected ? "proxy" : "proxy-off")
                : (Vpn.connected ? "vpn" : "vpn-off")
            case "nightlight": return NightLight.enabled ? "nightlight" : "nightlight-off"
            case "brightness": return Brightness.value <= 0 ? "brightness-off" : "brightness"
            case "notifications": return NotificationService.dnd ? "bell-off" : "bell"
            case "appmenu": return "menu"
            case "screenshot": return "screenshot"
            case "clipboard": return "clipboard"
            case "updates": return "updates"
            case "recording": return "record"
            case "power": return "power"
        }
        return ""
    }
    danger: cell.id === "power"
    badge: {
        if (cell.id === "updates") return Updates.count
        if (cell.id === "notifications") return NotificationService.list.length
        return 0
    }
    scrollable: cell.id === "volume" || cell.id === "brightness" || cell.id === "mic"
    selected: sidebarWin.selIndex >= 0 && sidebarWin.tiles[sidebarWin.selIndex] === btn
    value: {
        switch (cell.id) {
            case "volume": return Audio.volume
            case "brightness": return Brightness.value
            case "mic": return Audio.sourceVolume
        }
        return 0
    }
    onMoved: v => btn.applyValue(v)
    onActivated: {
        if (cell.id === "power") sidebarWin.ipcCall("powermenu")
        else if (cell.id === "appmenu") sidebarWin.ipcCall("appmenu")
        else if (cell.id === "vpn") Vpn.toggleMode() // tun <-> system-proxy; reconnects live if already on
        else if (cell.id === "screenshot") Quickshell.execDetached(["sh", "-c",
            // slurp first (cursor visible for region-picking), then hide the
            // cursor for the actual grab so it doesn't end up baked into the image.
            'g=$(slurp); [ -z "$g" ] && exit; hyprctl keyword cursor:invisible 1; ' +
            'f=~/screenshot_$(date +%Y%m%d_%H%M%S).png; grim -g "$g" "$f"; hyprctl keyword cursor:invisible 0; ' +
            'wl-copy < "$f" && imv "$f"'])
        else if (cell.id === "clipboard") sidebarWin.ipcCall("clipboard")
        else if (cell.id === "updates") Quickshell.execDetached(["kitty", "-e", "yay"])
        else if (cell.id === "recording") Recording.toggle()
        else if (cell.id === "network") Quickshell.execDetached(["kitty", "-e", "nmtui"])
        else if (cell.id === "bluetooth") Quickshell.execDetached(["kitty", "-e", "bluetuith"])
    }
    onToggled: {
        if (cell.id === "network") Network.setWifiEnabled(!Network.wifiEnabled)
        else if (cell.id === "bluetooth") Bluetooth.setEnabled(!Bluetooth.enabled)
        else if (cell.id === "vpn") Vpn.toggle()
        else if (cell.id === "notifications") NotificationService.toggleDnd()
        else if (cell.id === "nightlight") NightLight.toggle()
        else if (cell.id === "screenshot") Quickshell.execDetached(["sh", "-c",
            'hyprctl keyword cursor:invisible 1; f=~/screenshot_$(date +%Y%m%d_%H%M%S).png; grim "$f"; ' +
            'hyprctl keyword cursor:invisible 0; wl-copy < "$f" && imv "$f"'])
        else if (scrollable) {
            // 0 (disabled) ↔ previous level. Remember the level on the way
            // down so the next right-click restores exactly where it was.
            if (value > 0) { btn.prevValue = value; btn.applyValue(0) }
            else btn.applyValue(btn.prevValue > 0 ? btn.prevValue : 0.5)
        }
    }
    Component.onCompleted: sidebarWin.register(btn)
    Component.onDestruction: sidebarWin.unregister(btn)

    Rectangle {
        visible: cell.id === "recording" && Recording.active
        anchors { top: parent.top; right: parent.right; topMargin: 4; rightMargin: 4 }
        width: 8; height: 8
        radius: 4
        color: Theme.accent
        SequentialAnimation on opacity {
            running: cell.id === "recording" && Recording.active
            loops: Animation.Infinite
            NumberAnimation { from: 1; to: 0.3; duration: 600 }
            NumberAnimation { from: 0.3; to: 1; duration: 600 }
        }
    }
}
