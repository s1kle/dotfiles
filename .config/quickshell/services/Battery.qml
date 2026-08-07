pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    readonly property bool mock: !!Quickshell.env("QS_MOCK_LAPTOP")

    // --- mock state ---
    property real mockPercentage: 82
    property bool mockCharging: false

    readonly property var device: mock ? null : UPower.displayDevice
    readonly property bool available: mock ? true : device !== null && device.isLaptopBattery && device.ready

    readonly property int percentage: available ? Math.round(mock ? root.mockPercentage : device.percentage * 100) : -1
    readonly property bool charging: available && (mock ? root.mockCharging : device.state === UPowerDeviceState.Charging)
    readonly property bool discharging: available && (mock ? !root.mockCharging && root.mockPercentage < 100 : device.state === UPowerDeviceState.Discharging)
    readonly property bool fullyCharged: available && (mock ? root.mockPercentage >= 100 : device.state === UPowerDeviceState.FullyCharged)
    readonly property string iconName: available ? (mock ? root.mockIcon : device.iconName) : ""

    readonly property string mockIcon: {
        const lvl = root.mockPercentage
        const base = lvl >= 90 ? "battery-full-symbolic"
            : lvl >= 60 ? "battery-good-symbolic"
            : lvl >= 40 ? "battery-low-symbolic"
            : lvl >= 20 ? "battery-caution-symbolic"
            : "battery-empty-symbolic"
        return root.mockCharging ? base.replace("-symbolic", "-charging-symbolic") : base
    }

    readonly property string mockTimeLabel: formatTime(
        root.mockCharging ? Math.max(600, 3000 - root.mockPercentage * 20) : root.mockPercentage * 90)

    readonly property string timeLabel: {
        if (!available || percentage < 0) return ""
        if (mock) return root.mockTimeLabel
        const seconds = discharging ? device.timeToEmpty : device.timeToFull
        return formatTime(seconds)
    }

    function formatTime(seconds: real): string {
        if (seconds <= 0 || seconds > 60 * 60 * 24 || !isFinite(seconds)) return ""
        const h = Math.floor(seconds / 3600)
        const m = Math.round((seconds % 3600) / 60)
        if (h <= 0) return `${m}m`
        return `${h}h ${m}m`
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.mock
        onTriggered: {
            if (root.mockCharging) {
                root.mockPercentage = Math.min(100, root.mockPercentage + 3)
                if (root.mockPercentage >= 100) root.mockCharging = false
            } else {
                root.mockPercentage = Math.max(15, root.mockPercentage - 1)
                if (root.mockPercentage <= 15) root.mockCharging = true
            }
        }
    }
}
