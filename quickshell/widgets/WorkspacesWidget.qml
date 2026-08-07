import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

import qs.services

Rectangle {
    id: root
    // ponytail: single-monitor case matches SettingsWidget width (240)
    width: Hyprland.monitors.values.length === 1 ? 240 : 115
    height: 75
    radius: 12
    color: Theme.primary

    property int monitorIndex: 0

    readonly property var monitor: Hyprland.monitors.values[root.monitorIndex]
    readonly property var workspaces: Hyprland.workspaces.values.filter(ws => ws.monitor === root.monitor)

    visible: root.monitor !== undefined && root.monitor !== null

    Process {
        id: wsProc
    }

    Column {
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: `MONITOR ${root.monitorIndex + 1}`
            font.family: "Annotation Mono"
            font.pixelSize: 11
            color: Theme.text
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Repeater {
                model: [1, 2, 3]

                delegate: Rectangle {
                    required property var modelData

                    readonly property var ws: root.workspaces.find(w => w.id === modelData)
                    readonly property bool isCurrent: ws !== undefined && ws.active
                    readonly property bool hasWindows: ws !== undefined && ws.toplevels.values.length > 0

                    width: isCurrent ? 32 : 16
                    height: 16
                    radius: 8
                    color: isCurrent ? Theme.accent : (hasWindows ? Theme.secondary : Theme.accentMuted)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (ws)
                                ws.activate()
                            else
                                wsProc.exec(["hyprctl", "dispatch", `hl.dsp.focus({workspace=${modelData}})`])
                        }
                    }
                }
            }
        }
    }
}
