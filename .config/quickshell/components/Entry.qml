import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell

import qs.services

// App-menu entry pill (fixed width): icon (only if it exists) + name. Long names
// scroll (marquee). `selected` draws an accent border.
Item {
    id: root

    property string name: "App"
    property var icon: null // freedesktop icon name, or null
    property bool selected: false

    // iconPath(name, true) returns "" when the icon doesn't exist, so this hides
    // broken/missing icons. Resolve it synchronously (not via Image.Ready): gating
    // layout on the async decode reflows the row when it finishes, which blinks
    // long (overflowing) names on first appearance.
    readonly property string iconSource: root.icon ? Quickshell.iconPath(root.icon, true) : ""
    readonly property bool hasIcon: root.iconSource !== ""

    implicitWidth: 150
    implicitHeight: 36

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.surface
        border.width: root.selected ? 2 : 0
        border.color: Theme.accent

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#73000000" // black @ 0.45
            blurMax: 16
            shadowBlur: 1.0
            shadowHorizontalOffset: -8
            shadowVerticalOffset: 8
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: root.hasIcon ? 8 : 0

        Image {
            id: iconImg
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: root.hasIcon ? 20 : 0
            Layout.preferredHeight: 20
            visible: root.hasIcon
            asynchronous: true
            sourceSize: Qt.size(20, 20)
            source: root.iconSource
        }

        Item {
            id: nameClip
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: label.implicitHeight
            clip: true

            Text {
                id: label
                text: root.name
                color: Theme.text
                font.family: Config.font.family
                font.pixelSize: 13
                x: 0

                // span = clip width - text width, negative when the text overflows.
                // implicitWidth settles a frame or two after the name changes (font
                // /layout metrics), so span is the single source of truth and any
                // change to it restarts the marquee below.
                readonly property real span: nameClip.width - implicitWidth
                readonly property bool overflow: span < 0
                readonly property real scrollDur: Math.max(1, -span) * 25

                // Delegates are reused as results change, and implicitWidth settles
                // late. Fully restart the marquee (stop, pin x to 0, start from the
                // leading pause) on any name or span change: a stale in-flight scroll
                // is killed, and a width that settles during the pause just restarts
                // cleanly instead of scrolling to a stale, barely-overflowing offset.
                function resetMarquee() {
                    marquee.stop()
                    x = 0
                    if (overflow)
                        marquee.start()
                }
                onTextChanged: resetMarquee()
                onSpanChanged: resetMarquee()
                Component.onCompleted: resetMarquee()

                SequentialAnimation {
                    id: marquee
                    loops: Animation.Infinite
                    PropertyAction { target: label; property: "x"; value: 0 }
                    PauseAnimation { duration: 1200 }
                    NumberAnimation { target: label; property: "x"; from: 0; to: label.span; duration: label.scrollDur; easing.type: Easing.InOutQuad }
                    PauseAnimation { duration: 1200 }
                    NumberAnimation { target: label; property: "x"; from: label.span; to: 0; duration: label.scrollDur; easing.type: Easing.InOutQuad }
                }
            }
        }
    }
}
