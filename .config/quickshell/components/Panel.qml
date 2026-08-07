import QtQuick
import QtQuick.Effects

import qs.services

// Rounded card: surface fill + bottom-left drop shadow, no border.
// Body content (e.g. a Progress ring) goes in the default slot, pinned top;
// the uppercase `title` sits at the bottom (space-between). size from Config.
Item {
    id: root

    property int size: Config.panel.size
    property int padding: 12
    property string title: "NAME"
    property bool bodyCentered: false // false: body pinned top (space-between); true: vertically centered
    property bool titleStrikethrough: false
    property bool titleInteractive: false // enables click + pointing-hand cursor on the title
    signal titleClicked()
    default property alias content: body.data

    implicitWidth: root.size
    implicitHeight: root.size

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Config.layout.radius
        color: Theme.surface

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#80000000" // black @ 0.5
            shadowBlur: 1.0
            shadowHorizontalOffset: -12
            shadowVerticalOffset: 12
        }
    }

    Item {
        id: body
        anchors.horizontalCenter: card.horizontalCenter
        y: root.bodyCentered ? (root.height - height) / 2 : root.padding
        width: childrenRect.width
        height: childrenRect.height
    }

    Loader {
        anchors.bottom: card.bottom
        anchors.bottomMargin: root.padding
        anchors.horizontalCenter: card.horizontalCenter
        sourceComponent: root.titleInteractive ? clickableTitle : plainTitle

        Component {
            id: plainTitle
            Label {
                text: root.title
                strikethrough: root.titleStrikethrough
            }
        }

        Component {
            id: clickableTitle
            ClickableLabel {
                text: root.title
                strikethrough: root.titleStrikethrough
                onClicked: root.titleClicked()
            }
        }
    }
}
