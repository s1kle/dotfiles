import QtQuick

import qs.components
import qs.services

// Ring-gauge tile: a small Progress ring labelled `label`, with a `detail`
// flyout. value is 0..1 (controlled by the module). Covers cpu/mem/disk/
// battery/download/upload by props alone.
RailTile {
    id: root

    property string label: ""
    property real value: 0
    property string detail: ""

    Progress {
        anchors.centerIn: parent
        value: root.value
        size: root.size - 6
        lineWidth: 4
        showLabel: false
    }

    Text {
        anchors.centerIn: parent
        text: root.label
        color: root.hovered ? Theme.text : Theme.textDim
        font.family: Config.font.family
        font.pixelSize: 11
    }

    Flyout { visible: root.hovered; text: root.detail }
}
