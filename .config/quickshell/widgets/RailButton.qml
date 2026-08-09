import QtQuick

import qs.components
import qs.services

// Glyph tile with the ScrollableBox interaction. Optional inline slider flyout
// (showSlider) for volume/brightness/mic; otherwise a text `detail` flyout.
// Re-emits moved/activated/toggled for the module to route to a service, and
// re-exposes stepUp/stepDown for the module's PgUp/PgDn keyboard nav.
RailTile {
    id: root

    property string iconName: ""
    property string label: ""
    property string detail: ""
    property real value: 0
    property bool showSlider: false
    property bool scrollable: true
    signal moved(real value)
    signal activated()
    signal toggled()

    function stepUp(): void { box.stepUp() }
    function stepDown(): void { box.stepDown() }

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

    Flyout {
        visible: root.hovered

        Row {
            spacing: 8
            visible: root.showSlider

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.label
                color: Theme.textDim
                font.family: Config.font.family
                font.pixelSize: 11
            }
            Slider {
                anchors.verticalCenter: parent.verticalCenter
                width: 90
                value: root.value
                onMoved: v => root.moved(v)
            }
        }

        Text {
            visible: !root.showSlider
            text: root.detail
            color: Theme.text
            font.family: Config.font.family
            font.pixelSize: 12
        }
    }
}
