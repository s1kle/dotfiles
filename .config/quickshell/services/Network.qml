pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick

Singleton {
    id: root

    readonly property bool mock: !!Quickshell.env("QS_MOCK_LAPTOP")

    // --- mock state ---
    property var mockNetworks: []
    property bool mockWiredConnected: true
    property bool mockWifiEnabled: true
    property bool mockWifiHardwareEnabled: true

    readonly property bool mockWifiConnected: mockNetworks.some(n => n.connected)

    readonly property var devices: mock ? {
        values: [
            { type: DeviceType.Wired, name: "eth0", connected: root.mockWiredConnected, address: "192.168.1.50" },
            { type: DeviceType.Wifi, name: "wlan0", connected: root.mockWifiConnected, address: "192.168.1.51" },
        ]
    } : Networking.devices

    readonly property var mockPrimary: {
        if (root.mockWiredConnected) return { type: DeviceType.Wired, name: "eth0", connected: true, address: "192.168.1.50" }
        if (root.mockWifiConnected) return { type: DeviceType.Wifi, name: "wlan0", connected: true, address: "192.168.1.51" }
        return null
    }

    readonly property var primaryDevice: mock ? root.mockPrimary : activeDevice(devices.values)
    readonly property bool connected: mock ? (root.mockPrimary?.connected ?? false) : (primaryDevice?.connected ?? false)
    readonly property bool wifiEnabled: mock ? root.mockWifiEnabled : Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: mock ? root.mockWifiHardwareEnabled : Networking.wifiHardwareEnabled

    readonly property var connectivity: mock ? NetworkConnectivity.Full : Networking.connectivity
    readonly property string connectivityLabel: NetworkConnectivity.toString(connectivity)

    readonly property string address: primaryDevice?.address ?? ""

    readonly property var wifiDevice: mock ? {
        type: DeviceType.Wifi,
        name: "wlan0",
        networks: { values: root.mockNetworks },
    } : wifiDevices(devices.values)

    readonly property var networks: wifiDevice?.networks.values ?? []

    readonly property var activeNetwork: {
        for (const network of networks) {
            if (network.connected) return network
        }
        return null
    }

    readonly property int wifiStrength: Math.round((activeNetwork?.signalStrength ?? 0) * 100)
    readonly property string wifiSsid: activeNetwork?.name ?? ""

    function activeDevice(values): var {
        for (const device of values) {
            if (device.connected) return device
        }
        return values[0] ?? null
    }

    function wifiDevices(values): var {
        for (const device of values) {
            if (device.type === DeviceType.Wifi) return device
        }
        return null
    }

    function setWifiEnabled(enabled: bool): void {
        if (mock) {
            root.mockWifiEnabled = enabled
            return
        }
        Networking.wifiEnabled = enabled;
    }

    function connectTo(network: var): void {
        if (mock) {
            root.mockNetworks = root.mockNetworks.map(n => Object.assign({}, n, {
                connected: n.name === network.name,
                state: n.name === network.name ? ConnectionState.Connected : ConnectionState.Disconnected,
            }))
            return
        }
        network.connect();
    }

    function connectWithPsk(network: var, psk: string): void {
        if (mock) { root.connectTo(network); return }
        network.connectWithPsk(psk);
    }

    function disconnectNetwork(network: var): void {
        if (mock) {
            root.mockNetworks = root.mockNetworks.map(n => n.name === network.name ? Object.assign({}, n, { connected: false, state: ConnectionState.Disconnected }) : n)
            return
        }
        network.disconnect();
    }

    function disconnectDevice(): void {
        if (mock) {
            root.mockWiredConnected = false
            if (root.mockWifiConnected) {
                root.mockNetworks = root.mockNetworks.map(n => Object.assign({}, n, { connected: false, state: ConnectionState.Disconnected }))
            }
            return
        }
        primaryDevice?.disconnect();
    }

    Component.onCompleted: {
        if (mock) {
            root.mockNetworks = [
                { name: "HomeWiFi-5G", connected: true, known: true, signalStrength: 0.92,
                  security: WifiSecurityType.Wpa2Psk, state: ConnectionState.Connected },
                { name: "HomeWiFi", connected: false, known: true, signalStrength: 0.78,
                  security: WifiSecurityType.Wpa2Psk, state: ConnectionState.Disconnected },
                { name: "Cafe-Guest", connected: false, known: false, signalStrength: 0.55,
                  security: WifiSecurityType.Open, state: ConnectionState.Disconnected },
                { name: "NeighborNet", connected: false, known: false, signalStrength: 0.30,
                  security: WifiSecurityType.Wpa2Psk, state: ConnectionState.Disconnected },
                { name: "FreeWifi", connected: false, known: false, signalStrength: 0.15,
                  security: WifiSecurityType.Unknown, state: ConnectionState.Disconnected },
            ]
        }
    }

    IpcHandler {
        target: "network"
        function cycleConnection(): void {
            if (root.connected) root.disconnectDevice();
            else if (root.networks.length > 0) root.connectTo(root.networks[0]);
        }
    }
}
