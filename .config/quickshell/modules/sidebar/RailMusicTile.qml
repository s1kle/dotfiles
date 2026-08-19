import Quickshell.Widgets
import QtQuick

import qs.services
import qs.components
import qs.widgets

// Music card: cover art, transport buttons, ":(" placeholder when no player
// is active. `sidebarWin` supplies hasMusic.
RailCard {
    required property var sidebarWin
    property var cell: parent ? parent.cell : ({ cols: 4 })
    cols: cell.cols
    // vertical card (fits the narrow rail); ":(" placeholder when idle.
    Item {
        width: parent.width
        height: sidebarWin.hasMusic ? full.implicitHeight : 64

        Text {
            visible: !sidebarWin.hasMusic
            anchors.centerIn: parent
            text: ":("
            color: Theme.textDim
            font.family: Config.font.family
            font.pixelSize: 26
        }

        Column {
            id: full
            visible: sidebarWin.hasMusic
            width: parent.width
            spacing: 6

            ClippingRectangle {
                width: parent.width
                height: 110
                radius: 12
                color: "transparent"
                Rectangle {
                    anchors.fill: parent
                    visible: !cover.visible
                    gradient: Gradient {
                        GradientStop { position: 0; color: Theme.accent }
                        GradientStop { position: 1; color: Theme.accentHover }
                    }
                }
                Image {
                    id: cover
                    anchors.fill: parent
                    source: Mpris.activePlayer ? Mpris.activePlayer.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: source !== "" && status === Image.Ready
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Mpris.activePlayer ? Mpris.activePlayer.trackTitle : ""
                color: Theme.text
                font.family: Config.font.family
                font.pixelSize: 12
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Mpris.activePlayer ? Mpris.activePlayer.trackArtist : ""
                color: Theme.textDim
                font.family: Config.font.family
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                Button { text: "Prev"; fontSize: 11; hpad: 7; textColor: Theme.textDim; enabled: Mpris.canGoPrevious; onClicked: Mpris.previous() }
                Button { text: Mpris.isPlaying ? "Pause" : "Play"; fontSize: 11; hpad: 7; textColor: Theme.text; onClicked: Mpris.togglePlaying() }
                Button { text: "Next"; fontSize: 11; hpad: 7; textColor: Theme.textDim; enabled: Mpris.canGoNext; onClicked: Mpris.next() }
            }
        }
    }
}
