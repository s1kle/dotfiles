import QtQuick

import qs.services

// Dumb horizontal slider: accentMuted pill track + accent fill. value is 0..1
// (controlled — the fill follows `value`). Dragging emits moved(value).
// thickness (line height) from Config; width is set by the consumer.
Item {
    id: root

    property real value: 0.3
    property int thickness: Config.slider.thickness
    signal moved(real value)

    implicitWidth: 156
    implicitHeight: root.thickness

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.accentMuted

        Rectangle {
            width: Math.max(height, parent.width * root.value)
            height: parent.height
            radius: height / 2
            color: Theme.accent
        }
    }

    MouseArea {
        anchors.fill: parent
        function apply(x: real): void { root.moved(Math.max(0, Math.min(1, x / width))) }
        onPressed: mouse => apply(mouse.x)
        onPositionChanged: mouse => { if (pressed) apply(mouse.x) }
    }
}
