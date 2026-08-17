import QtQuick

import qs.services

// Thin horizontal progress bar. value 0..1. When seekable, click/drag emits
// seek(fraction).
Item {
    id: root

    property real value: 0
    property bool seekable: false
    signal seek(real fraction)

    implicitHeight: 4

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Theme.primary

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: parent.radius
            color: Theme.accent
        }
    }

    // taller than the 4px track so it's easy to grab
    MouseArea {
        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        enabled: root.seekable
        cursorShape: Qt.PointingHandCursor
        function emitAt(x) { root.seek(Math.max(0, Math.min(1, x / width))) }
        onPressed: e => emitAt(e.x)
        onPositionChanged: e => { if (pressed) emitAt(e.x) }
    }
}
