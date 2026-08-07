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

    // iconPath(name, true) returns "" when the icon doesn't exist; combined with
    // the load status this hides broken/missing icons instead of showing them.
    readonly property bool hasIcon: !!root.icon && iconImg.status === Image.Ready

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
            source: root.icon ? Quickshell.iconPath(root.icon, true) : ""
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

                readonly property bool overflow: implicitWidth > nameClip.width
                readonly property real scrollDur: Math.max(1, implicitWidth - nameClip.width) * 25

                SequentialAnimation on x {
                    running: label.overflow
                    loops: Animation.Infinite
                    PauseAnimation { duration: 1200 }
                    NumberAnimation { from: 0; to: nameClip.width - label.implicitWidth; duration: label.scrollDur; easing.type: Easing.InOutQuad }
                    PauseAnimation { duration: 1200 }
                    NumberAnimation { from: nameClip.width - label.implicitWidth; to: 0; duration: label.scrollDur; easing.type: Easing.InOutQuad }
                }
            }
        }
    }
}
