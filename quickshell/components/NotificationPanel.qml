import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import qs.services

// Rounded card with the title at the TOP and left-aligned, content-height
// stacked body (title, then default children). Fixed width; bottom-left shadow.
// Whole card is clickable (clicked signal).
Item {
    id: root

    property string title: "NAME"
    property int panelWidth: 260
    readonly property int padH: 16
    readonly property int padV: 14
    default property alias content: col.data
    signal clicked()

    implicitWidth: root.panelWidth
    implicitHeight: col.implicitHeight + 2 * root.padV

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Config.layout.radius
        color: Theme.surface

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#80000000" // black @ 0.5
            blurMax: 18 // cap blur so the shadow's reach is bounded (~30px)
            shadowBlur: 1.0
            shadowHorizontalOffset: -12
            shadowVerticalOffset: 12
        }
    }

    ColumnLayout {
        id: col
        x: root.padH
        y: root.padV
        width: root.panelWidth - 2 * root.padH
        spacing: 6

        Text {
            Layout.fillWidth: true
            text: root.title
            color: Theme.textDim
            font.family: Config.font.family
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 11 * 0.12 // 0.12em
            font.capitalization: Font.AllUppercase
        }
    }

    MouseArea {
        anchors.fill: card
        onClicked: root.clicked()
    }
}
