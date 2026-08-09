import QtQuick
import QtQuick.Effects
import Quickshell.Widgets

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
    property real fill: -1 // 0..1 bottom-up value fill shown on hover; <0 = none
    readonly property alias hovered: hover.hovered
    default property alias content: body.data

    // animated fill level: grows 0 -> value on hover, shrinks back on leave, and
    // eases to the new value while scrolling.
    property real fillLevel: (hover.hovered && root.fill >= 0) ? Math.max(0, Math.min(1, root.fill)) : 0
    Behavior on fillLevel { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

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

    // value fill, bottom-up, shown on hover (scrollable tiles). A plain rect
    // clipped to the card's rounded shape, so no colour ever spills outside the
    // tile — the level is a clean flat line, bottom corners follow the card.
    ClippingRectangle {
        anchors.fill: card
        radius: card.radius
        color: "transparent"
        visible: root.fill >= 0 // stays visible through the shrink-out animation

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: parent.height * root.fillLevel
            color: Theme.accent
        }
    }

    Item {
        id: body
        anchors.centerIn: card
        // cards inset content by `padding` (breathing room from the card edges);
        // buttons/gauges fill the whole tile so the click/scroll target is full.
        width: root.fitContent ? card.width - 2 * root.padding : card.width
        height: root.fitContent ? childrenRect.height : card.height
    }

    HoverHandler { id: hover }
}
