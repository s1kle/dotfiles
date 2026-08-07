import QtQuick

// A Label that reports clicks and shows a pointing-hand cursor.
Label {
    id: root

    signal clicked()

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
