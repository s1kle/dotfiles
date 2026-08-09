import QtQuick
import QtQuick.Effects
import Quickshell

import qs.services

// Monochrome SVG icon from assets/icons/<name>.svg, tinted to `color` via
// MultiEffect colorization (source colour is irrelevant — any opaque pixel is
// recoloured, alpha preserved). Used instead of emoji glyphs on the rail.
Item {
    id: root

    property string name: ""
    property color color: Theme.text
    property int size: 20

    implicitWidth: root.size
    implicitHeight: root.size

    Image {
        id: img
        anchors.fill: parent
        source: root.name !== "" ? Quickshell.shellPath("assets/icons/" + root.name + ".svg") : ""
        sourceSize: Qt.size(root.size, root.size)
        fillMode: Image.PreserveAspectFit
        visible: false
    }

    MultiEffect {
        anchors.fill: img
        source: img
        colorization: 1.0
        colorizationColor: root.color
    }
}
