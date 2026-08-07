import Quickshell
import QtQuick

import qs.services
import qs.widgets

// Test surface: a row of usage gauges at top-center, wired to live services.
PanelWindow {
    id: win

    color: "transparent"
    anchors { top: true; left: true; right: true }
    implicitHeight: Config.panel.size + Config.slider.height + 6 * Config.layout.margin
    exclusiveZone: 0

    // ponytail: fixed 100 Mbit/s ceiling for the network rings; make configurable if it matters.
    readonly property real netMax: 12.5 * 1024 * 1024

    Row {
        id: gauges
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Config.layout.margin
        spacing: 16

        CpuUsage { value: SystemUsage.cpuPerc / 100 }
        MemUsage { value: SystemUsage.memPerc / 100 }
        DiskUsage { value: SystemUsage.diskPerc / 100 }
        BatteryLevel {
            visible: Battery.available
            value: Battery.percentage / 100
        }
        DownloadUsage { value: Math.min(1, SystemUsage.downloadSpeed / win.netMax) }
        UploadUsage { value: Math.min(1, SystemUsage.uploadSpeed / win.netMax) }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: gauges.bottom
        anchors.topMargin: 2 * Config.layout.margin
        spacing: 16

        BrightnessSlider {
            visible: Brightness.available
            value: Brightness.value
            onMoved: v => Brightness.set(v)
        }
        OutputVolume {
            visible: Audio.sink !== null
            value: Audio.volume
            onMoved: v => Audio.setVolume(v)
        }
        InputVolume {
            visible: Audio.source !== null
            value: Audio.sourceVolume
            onMoved: v => Audio.setSourceVolume(v)
        }
    }
}
