import QtQuick
import QtQuick.Effects

import qs.services
import qs.components

// Radial power-menu entry: icon + label. `armed` is the "click again to
// confirm" state for Reboot/Shutdown — filled accent background, label
// becomes "Confirm?".
Item {
    id: root

    property string label: ""
    property string iconName: ""
    property bool selected: false
    property bool armed: false

    implicitWidth: 88
    implicitHeight: 88

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: root.armed ? Theme.accent : Theme.surface
        border.width: root.selected ? 2 : 0
        border.color: Theme.accent
        Behavior on color { ColorAnimation { duration: 160 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#73000000"
            blurMax: 16
            shadowBlur: 1.0
            shadowHorizontalOffset: -8
            shadowVerticalOffset: 8
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 6
        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: root.iconName
            size: 22
            color: root.armed ? Theme.background : Theme.text
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.armed ? "Confirm?" : root.label
            color: root.armed ? Theme.background : Theme.textDim
            font.family: Config.font.family
            font.pixelSize: 11
        }
    }
}
