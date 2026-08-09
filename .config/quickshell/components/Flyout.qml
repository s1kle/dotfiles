import QtQuick

import qs.services

// Hover popup anchored to the LEFT of its parent tile. Bind `visible` to the
// tile's `hovered`. Shows `text`, or override the default slot with custom
// content (e.g. a slider). Fades in; z lifted so it floats over neighbours.
Rectangle {
    id: root

    property string text: ""
    default property alias content: slot.data

    anchors.right: parent.left
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    z: 100

    implicitWidth: slot.childrenRect.width + 24
    implicitHeight: slot.childrenRect.height + 16
    radius: 10
    color: Theme.surface
    opacity: visible ? 1 : 0
    visible: false

    Behavior on opacity { NumberAnimation { duration: 180 } }

    Item {
        id: slot
        anchors.centerIn: parent
        width: childrenRect.width
        height: childrenRect.height

        Text {
            // default label: shown only when no custom content was supplied
            visible: root.text !== "" && slot.children.length === 1
            text: root.text
            color: Theme.text
            font.family: Config.font.family
            font.pixelSize: 12
        }
    }
}
