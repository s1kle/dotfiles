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
    property int padding: 8
    property bool selected: false
    property bool danger: false
    property bool hoverRecolor: true
    property bool fitContent: false // true: grow to fit content (wide cards)
    readonly property alias hovered: hover.hovered
    default property alias content: body.data

    implicitWidth: root.size
    // square by default; cards grow to fit their content
    implicitHeight: root.fitContent ? Math.max(root.size, body.height + 2 * root.padding) : root.size

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
        // always full tile width (so wide cards can space content across it and
        // buttons get a full click/scroll target); cards fit their content
        // height so the tile grows vertically around it.
        width: card.width
        height: root.fitContent ? childrenRect.height : card.height
    }

    HoverHandler { id: hover }
}
