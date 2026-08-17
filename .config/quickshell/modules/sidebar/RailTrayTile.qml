import QtQuick

import qs.services
import qs.widgets

// SNI tray card. Left-click activates (or opens the menu if activate() is a
// no-op for that item); right-click always opens the menu. `sidebarWin` is passed
// through as the anchor window for modelData.display().
RailCard {
    required property var sidebarWin
    property var cell: parent ? parent.cell : ({ cols: 4 })
    cols: cell.cols
    Flow {
        width: parent.width
        spacing: 8
        Repeater {
            model: SystemTray.items
            delegate: Item {
                required property var modelData
                width: 28; height: 28
                Image {
                    anchors.centerIn: parent
                    // modelData.icon is already a Quickshell image-provider
                    // URL ("image://icon/...") for SNI items — use it as-is,
                    // unlike .desktop-file icon names elsewhere which need
                    // Quickshell.iconPath() to resolve a bare theme name.
                    source: modelData.icon
                    sourceSize: Qt.size(20, 20)
                }
                TapHandler {
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onTapped: (point, button) => {
                        // Most tray items here (network/bluetooth/volume-style
                        // indicators) are menu-only — activate() is a no-op for
                        // them. Left-click opens the menu too when one exists;
                        // right-click always does (standard secondary action).
                        if (button === Qt.RightButton || modelData.hasMenu)
                            modelData.display(sidebarWin, point.position.x, point.position.y)
                        else
                            modelData.activate()
                    }
                }
            }
        }
        Text {
            visible: SystemTray.items.length === 0
            text: "no tray items"
            color: Theme.textDim
            font.family: Config.font.family
            font.pixelSize: 11
        }
    }
}
