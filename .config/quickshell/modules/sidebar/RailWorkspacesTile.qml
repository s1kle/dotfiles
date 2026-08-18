import QtQuick

import qs.services
import qs.widgets

// Hyprland workspace-dot card: one row per monitor (name then its own dots),
// so a second monitor's workspaces never bleed into the first's and the rows
// don't shuffle around as focus moves between monitors.
RailCard {
    property var cell: parent ? parent.cell : ({ cols: 4 })
    cols: cell.cols
    Column {
        width: parent.width
        spacing: 8
        Repeater {
            model: Hyprland.monitors
            delegate: Item {
                required property var modelData
                width: parent.width
                height: Math.max(label.implicitHeight, dots.implicitHeight)

                Text {
                    id: label
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left }
                    text: modelData.name.toUpperCase()
                    color: Theme.textDim
                    font.family: Config.font.family
                    font.pixelSize: 12
                }

                Row {
                    id: dots
                    anchors { verticalCenter: parent.verticalCenter; right: parent.right }
                    spacing: 12
                    Repeater {
                        model: Hyprland.workspacesForMonitor(modelData.name)
                        delegate: Rectangle {
                            required property var modelData
                            width: 18; height: 18; radius: 9
                            color: modelData.active ? Theme.accent : (modelData.occupied ? Theme.textDim : "transparent")
                            border.width: modelData.occupied || modelData.active ? 0 : 2
                            border.color: Theme.accentMuted
                            TapHandler { onTapped: Hyprland.switchTo(modelData.id) }
                        }
                    }
                }
            }
        }
    }
}
