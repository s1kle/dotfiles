import QtQuick
import QtQuick.Effects

import qs.services

// Dumb: morning / now / evening forecast. Each slot is ({ temp, icon }) where
// icon is a resolved SVG source URL, or null to hide the slot. Dim sides, bright
// center. The SVG is tinted to a Theme token via MultiEffect.
Row {
    id: root

    property var morning: null
    property var now: null
    property var evening: null

    spacing: 14

    Repeater {
        model: [
            ({ d: root.morning, center: false }),
            ({ d: root.now, center: true }),
            ({ d: root.evening, center: false })
        ]

        delegate: Column {
            id: slot
            required property var modelData
            readonly property var d: modelData.d
            readonly property bool center: modelData.center

            visible: d !== null
            spacing: 2

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: slot.center ? 22 : 15
                height: width

                Image {
                    id: img
                    anchors.fill: parent
                    visible: false
                    sourceSize: Qt.size(width, height)
                    source: slot.d ? slot.d.icon : ""
                }
                MultiEffect {
                    anchors.fill: parent
                    source: img
                    colorization: 1
                    colorizationColor: slot.center ? Theme.text : Theme.textDim
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: slot.d ? (slot.d.temp + "°") : ""
                color: slot.center ? Theme.text : Theme.textDim
                font.family: Config.font.family
                font.pixelSize: slot.center ? 13 : 11
            }
        }
    }
}
