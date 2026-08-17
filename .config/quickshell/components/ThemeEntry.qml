import QtQuick
import QtQuick.Effects

import qs.services

// Theme-switcher card: name (centered) over a palette preview row. The swatches
// use the entry's OWN palette so each card shows its theme regardless of the
// current live preview.
Item {
    id: root

    property string name: "Theme"
    property var palette: ({})
    property bool selected: false

    // Ordered subset shown as swatches.
    readonly property var swatchKeys: ["background", "surface", "accent", "accentHover", "text"]

    implicitWidth: 168
    implicitHeight: 52

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.surface
        border.width: root.selected ? 2 : 0
        border.color: Theme.accent

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#73000000" // black @ 0.45
            blurMax: 16
            shadowBlur: 1.0
            shadowHorizontalOffset: -8
            shadowVerticalOffset: 8
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.name
            color: Theme.text
            font.family: Config.font.family
            font.pixelSize: 13
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.width - 24)
            horizontalAlignment: Text.AlignHCenter
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            Repeater {
                model: root.swatchKeys
                delegate: Rectangle {
                    required property string modelData
                    width: 18
                    height: 12
                    radius: 3
                    color: root.palette[modelData] ?? "transparent"
                    border.width: 1
                    border.color: "#33000000"
                }
            }
        }
    }
}
