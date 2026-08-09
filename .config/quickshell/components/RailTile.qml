import QtQuick
import QtQuick.Effects

import qs.services

// A rounded rail tile: surface fill + bottom-left drop shadow, hover recolor,
// optional keyboard-selection ring. `cols` spans grid columns (width set by the
// parent layout via width binding). Content is centered in the default slot.
Item {
    id: root

    property int size: Config.sidebar.tileSize
    property int cols: 1
    property bool selected: false
    property bool danger: false
    property bool hoverRecolor: true
    readonly property alias hovered: hover.hovered
    default property alias content: body.data

    implicitWidth: root.size
    implicitHeight: root.size

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Config.layout.radius
        color: root.danger && hover.hovered ? Theme.accent
            : (root.hoverRecolor && hover.hovered) ? Theme.secondary : Theme.surface
        border.width: root.selected ? 2 : 0
        border.color: Theme.accent

        Behavior on color { ColorAnimation { duration: 160 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#73000000" // black @ 0.45
            blurMax: 24
            shadowBlur: 1.0
            shadowHorizontalOffset: -7
            shadowVerticalOffset: 7
        }
    }

    Item {
        id: body
        anchors.centerIn: card
        width: childrenRect.width
        height: childrenRect.height
    }

    HoverHandler { id: hover }
}
