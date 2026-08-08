import QtQuick
import QtQuick.Shapes

// Vector media-control glyph (QtQuick.Shapes, so it recolors with `color`).
// kind: "prev" | "next" | "play" | "pause". Emits clicked() when enabled.
Item {
    id: root

    property string kind: "play"
    property int size: 15
    property color color: "#ffffff"
    property bool enabled: true
    signal clicked()

    implicitWidth: size
    implicitHeight: size

    // glyphs authored in a 0..24 viewBox, scaled to `size`
    readonly property var paths: ({
        play: "M8 6 L18 12 L8 18 Z",
        pause: "M8 6 H11 V18 H8 Z M13 6 H16 V18 H13 Z",
        next: "M7 6 L15 12 L7 18 Z M16 6 H18 V18 H16 Z",
        prev: "M6 6 H8 V18 H6 Z M17 6 L9 12 L17 18 Z"
    })

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        transform: Scale { xScale: root.size / 24; yScale: root.size / 24 }

        ShapePath {
            fillColor: root.enabled ? root.color : Qt.rgba(root.color.r, root.color.g, root.color.b, 0.4)
            strokeWidth: 0
            PathSvg { path: root.paths[root.kind] ?? root.paths.play }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
