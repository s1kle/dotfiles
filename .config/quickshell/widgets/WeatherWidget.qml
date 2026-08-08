import QtQuick

import qs.services

// Dumb: morning / now / evening forecast. Each slot is ({ temp, icon }) where
// icon is a resolved SVG source URL, or null to hide the slot. Icons keep their
// own natural colors (theme-independent); side slots are dimmed with opacity.
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
            opacity: slot.center ? 1 : 0.7
            spacing: 2

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                width: slot.center ? 22 : 15
                height: width
                sourceSize: Qt.size(width, height)
                fillMode: Image.PreserveAspectFit
                source: slot.d ? slot.d.icon : ""
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: slot.d ? (slot.d.temp + "°") : ""
                color: Theme.text
                font.family: Config.font.family
                font.pixelSize: slot.center ? 13 : 11
            }
        }
    }
}
