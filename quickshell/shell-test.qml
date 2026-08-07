import Quickshell
import Quickshell.Hyprland
import QtQuick

import qs.services

ShellRoot {
    id: root

    property int runs: 0

    // ponytail: smoke-test entry, run with: quickshell -p ~/.config/quickshell/shell-test.qml
    // logs every singleton once, then exits. Replace with real shell.qml for the full bar.

    Timer {
        interval: 8000
        repeat: true
        running: true
        onTriggered: {
            console.log("SMOKE", root.runs + 1, "Time:", Time.time, "|", Time.date)
            console.log("SMOKE Theme:", Theme.background, Theme.accent, Theme.text, "path:", Quickshell.shellPath("themes/NordTheme.json"))
            console.log("SMOKE Battery: avail", Battery.available, "pct", Battery.percentage, "charging", Battery.charging, "time", Battery.timeLabel)
            console.log("SMOKE Audio: sink", Audio.sinkDescription, "vol", Audio.volume.toFixed(0), "muted", Audio.muted, "| sources:", Audio.sources.length)
            console.log("SMOKE Network: devices", Network.devices.values.length, "conn", Network.connectivityLabel, "addr", Network.address,
                        "wifi", Network.wifiEnabled && Network.wifiHardwareEnabled, "ssid", Network.wifiSsid, "strength", Network.wifiStrength,
                        "networks", Network.networks.length)
            console.log("SMOKE Mpris: players", Mpris.players.length, "active", Mpris.activePlayer?.dbusName ?? "none", "playing", Mpris.isPlaying)
            console.log("SMOKE Bluetooth: mock", Bluetooth.mock, "avail", Bluetooth.available, "enabled", Bluetooth.enabled,
                        "adapter", Bluetooth.adapterName, "devices", Bluetooth.devices.length, "conn", Bluetooth.connectedCount)
            for (const d of Bluetooth.devices) {
                console.log("SMOKE BT:", d.name, "conn", d.connected, "paired", d.paired, d.batteryAvailable ? "bat " + d.battery + "%" : "no-battery")
            }
            console.log("SMOKE Config: host", Config.hostname, "valid", Config.valid,
                        "theme", Config.theme.name,
                        "layout", Config.layout.barHeight + "x" + Config.layout.barWidth,
                        "radius", Config.layout.radius, "padding", Config.layout.padding,
                        "shadow", Config.shadow.blur + "/" + Config.shadow.opacity,
                        "font", Config.font.family, Config.font.sizes.bar + "/" + Config.font.sizes.clock + "/" + Config.font.sizes.title,
                        "widgets", JSON.stringify(Config.widgets))
            console.log("SMOKE SysUsage: gpu", SystemUsage.gpuType, "cpu", SystemUsage.cpuPerc.toFixed(0) + "%",
                        "mem", SystemUsage.memPerc.toFixed(0) + "%", "disk", SystemUsage.diskPerc.toFixed(0) + "%",
                        "net", SystemUsage.downloadSpeed.toFixed(0) + "B/s", "| lastTotal:", SystemUsage.lastCpuTotal)
            root.runs++
            if (root.runs >= 3) Qt.quit()
        }
    }

    Item {}
}
