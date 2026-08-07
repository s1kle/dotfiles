pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property bool mock: !!Quickshell.env("QS_MOCK_LAPTOP")

    // --- mock state ---
    property bool mockEnabled: true
    property var mockDevices: []

    readonly property var adapter: mock ? { name: "BT-5.3", enabled: root.mockEnabled } : Bluetooth.defaultAdapter
    readonly property bool available: mock ? true : Bluetooth.adapters.values.length > 0
    readonly property bool enabled: mock ? root.mockEnabled : (root.adapter?.enabled ?? false)
    readonly property string adapterName: root.adapter?.name ?? ""

    readonly property var devices: mock ? root.mockDevices : (root.adapter?.devices.values ?? [])
    readonly property int connectedCount: devices.filter(d => d.connected).length

    function setEnabled(enabled: bool): void {
        if (mock) {
            root.mockEnabled = enabled
            return
        }
        if (root.adapter) root.adapter.enabled = enabled
    }

    function connect(device: var): void {
        if (mock) {
            root.mockDevices = root.mockDevices.map(d => d.name === device.name
                ? Object.assign({}, d, { connected: true, state: BluetoothDeviceState.Connected }) : d)
            return
        }
        device.connect()
    }

    function disconnect(device: var): void {
        if (mock) {
            root.mockDevices = root.mockDevices.map(d => d.name === device.name
                ? Object.assign({}, d, { connected: false, state: BluetoothDeviceState.Disconnected }) : d)
            return
        }
        device.disconnect()
    }

    function forget(device: var): void {
        if (mock) {
            root.mockDevices = root.mockDevices.filter(d => d.name !== device.name)
            return
        }
        device.forget()
    }

    Component.onCompleted: {
        if (mock) {
            root.mockDevices = [
                { name: "MX Master 3S", icon: "input-mouse", address: "00:1F:22:AA:BB:CC",
                  connected: true, paired: true, state: BluetoothDeviceState.Connected,
                  batteryAvailable: true, battery: 87 },
                { name: "AirPods Pro", icon: "audio-headphones", address: "00:1F:22:DD:EE:FF",
                  connected: false, paired: true, state: BluetoothDeviceState.Disconnected,
                  batteryAvailable: true, battery: 41 },
                { name: "Keychron K8", icon: "input-keyboard", address: "00:1F:22:11:22:33",
                  connected: false, paired: false, state: BluetoothDeviceState.Disconnected,
                  batteryAvailable: false, battery: 0 },
            ]
        }
    }

    IpcHandler {
        target: "bluetooth"
        function toggle(): void { root.setEnabled(!root.enabled) }
    }
}
