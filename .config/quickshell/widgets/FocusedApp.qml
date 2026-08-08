import QtQuick
import Quickshell

import qs.services

// Dumb: focused-app icon (hidden if missing) + name. Placeholders: icon, name.
Row {
    id: root

    property string icon: ""
    property string name: ""
    property int maxNameWidth: 220 // cap so a long window title can't blow up the pill

    spacing: 6

    // iconPath(name, true) returns "" for missing icons -> hidden.
    readonly property string iconSource: root.icon ? Quickshell.iconPath(root.icon, true) : ""

    Image {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.iconSource !== ""
        width: visible ? 14 : 0
        height: 14
        sourceSize: Qt.size(14, 14)
        source: root.iconSource
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.name
        color: Theme.text
        font.family: Config.font.family
        font.pixelSize: 12
        elide: Text.ElideRight
        width: Math.min(implicitWidth, root.maxNameWidth)
    }
}
