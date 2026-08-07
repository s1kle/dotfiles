import Quickshell
import QtQuick

import qs.services
import qs.widgets

// Popup stack of live notifications at top-right, wired to NotificationService.
// Click a card or wait for its timeout to dismiss it.
PanelWindow {
    id: win

    color: "transparent"
    anchors { top: true; right: true }
    // sh: room for each card's bottom-left shadow so the window/siblings don't clip it.
    readonly property int sh: 32
    implicitWidth: 260 + win.sh + Config.layout.margin
    implicitHeight: Math.max(1, col.implicitHeight + 2 * win.sh)
    exclusiveZone: 0

    Column {
        id: col
        anchors { top: parent.top; right: parent.right; topMargin: win.sh; rightMargin: Config.layout.margin }
        spacing: win.sh

        Repeater {
            model: NotificationService.list

            delegate: Item {
                required property var modelData

                implicitWidth: card.implicitWidth
                implicitHeight: card.implicitHeight

                NotificationCard {
                    id: card
                    appName: modelData.appName || "Notification"
                    body: (modelData.body && modelData.body !== "") ? modelData.body : modelData.summary
                    image: modelData.image || ""
                    onClicked: modelData.dismiss()
                }

                Timer {
                    interval: modelData.expireTimeout > 0 ? modelData.expireTimeout : 5000
                    running: true
                    onTriggered: modelData.dismiss()
                }
            }
        }
    }
}
