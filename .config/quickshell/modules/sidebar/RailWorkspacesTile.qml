import QtQuick

import qs.services
import qs.widgets

// Hyprland workspace-dot card: monitor name (caps) then dots, left-aligned.
RailCard {
    property var cell: parent ? parent.cell : ({ cols: 4 })
    cols: cell.cols
    Row {
        spacing: 12

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Hyprland.monitorName.toUpperCase()
            color: Theme.textDim
            font.family: Config.font.family
            font.pixelSize: 12
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            Repeater {
                model: Hyprland.workspaces
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
