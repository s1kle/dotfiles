import QtQuick

import qs.components
import qs.services

// Glyph tile with the ScrollableBox interaction. Scrollable tiles show a
// bottom-up value fill on hover so the current level is readable at a glance;
// re-exposes stepUp/stepDown for the module's PgUp/PgDn keyboard nav.
RailTile {
    id: root

    property string iconName: ""
    property real value: 0
    property bool scrollable: true
    signal moved(real value)
    signal activated()
    signal toggled()

    function stepUp(): void { box.stepUp() }
    function stepDown(): void { box.stepDown() }

    // scrollable tiles: fill bottom-up to `value` on hover (no hover recolor so
    // the fill reads cleanly); other tiles keep the normal hover recolor.
    fill: root.scrollable ? root.value : -1
    hoverRecolor: !root.scrollable

    ScrollableBox {
        id: box
        anchors.fill: parent
        value: root.value
        scrollable: root.scrollable
        onMoved: v => root.moved(v)
        onActivated: root.activated()
        onToggled: root.toggled()

        Icon {
            anchors.centerIn: parent
            name: root.iconName
            size: 20
            color: root.danger && root.hovered ? Theme.background : Theme.text
        }
    }

    // contrast copy of the icon, clipped to the value fill (bottom-up), so the
    // portion the accent fill covers stays legible (background colour over accent).
    Item {
        id: iconFillMask
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: parent.height * root.fillLevel
        clip: true
        visible: root.scrollable

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            y: iconFillMask.height - root.height / 2 - height / 2
            name: root.iconName
            size: 20
            color: Theme.background
        }
    }
}
