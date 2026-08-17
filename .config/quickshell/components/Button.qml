import QtQuick

import qs.services

// Rounded box holding a centered text label. Clickable; dims when disabled.
Item {
    id: root

    property string text: ""
    property color background: Theme.primary
    property color hoverBackground: Theme.secondary
    property color textColor: Theme.text
    property int fontSize: 12
    property int hpad: 10
    property bool enabled: true
    signal clicked()

    implicitWidth: box.implicitWidth
    implicitHeight: box.implicitHeight
    opacity: root.enabled ? 1 : 0.4

    Rectangle {
        id: box
        anchors.fill: parent
        implicitWidth: label.implicitWidth + root.hpad * 2
        implicitHeight: 24
        radius: 8
        color: mouse.containsMouse ? root.hoverBackground : root.background
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: root.textColor
            font.family: Config.font.family
            font.pixelSize: root.fontSize
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
