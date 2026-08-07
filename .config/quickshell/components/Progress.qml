import QtQuick
import QtQuick.Shapes

import qs.services

// Circular progress ring: accentMuted track + accent value arc + centered %.
// value is 0..1 (placeholder default). size / lineWidth come from Config.
Item {
    id: root

    property real value: 0.3
    property int size: Config.progress.size
    property int lineWidth: Config.progress.width

    implicitWidth: root.size
    implicitHeight: root.size

    readonly property real _c: root.size / 2
    readonly property real _r: (root.size - root.lineWidth) / 2

    Behavior on value { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath { // track
            fillColor: "transparent"
            strokeColor: Theme.accentMuted
            strokeWidth: root.lineWidth
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root._c; centerY: root._c
                radiusX: root._r; radiusY: root._r
                startAngle: -90; sweepAngle: 360
            }
        }

        ShapePath { // value arc
            fillColor: "transparent"
            strokeColor: Theme.accent
            strokeWidth: root.lineWidth
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root._c; centerY: root._c
                radiusX: root._r; radiusY: root._r
                startAngle: -90; sweepAngle: 360 * root.value
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: Math.round(root.value * 100) + "%"
        color: Theme.text
        font.family: Config.font.family
        font.pixelSize: 14
        font.weight: Font.DemiBold
    }
}
