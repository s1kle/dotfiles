import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import qs.services
import qs.components

// Dumb: album cover + track/artist + prev/playpause/next + seekable progress.
// Placeholders below; signals go back to the module (which drives Mpris).
Row {
    id: root

    property string coverUrl: ""
    property string track: ""
    property string artist: ""
    property bool playing: false
    property bool canPrev: false
    property bool canNext: false
    property bool canSeek: false
    property real position: 0
    property real length: 0

    signal prev()
    signal next()
    signal playPause()
    signal seek(real fraction)

    spacing: 10

    // cover: gradient fallback, real art rounded on top when available
    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: 48
        height: 48

        Rectangle {
            anchors.fill: parent
            radius: 10
            visible: !art.visible
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.accent }
                GradientStop { position: 1; color: Theme.accentHover }
            }
        }
        Image {
            id: art
            anchors.fill: parent
            source: root.coverUrl
            fillMode: Image.PreserveAspectCrop
            visible: root.coverUrl !== "" && status === Image.Ready
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: artMask
            }
        }
        Item {
            id: artMask
            anchors.fill: parent
            layer.enabled: true
            visible: false
            Rectangle { anchors.fill: parent; radius: 10 }
        }
    }

    Column {
        id: main
        width: 178
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        RowLayout {
            width: parent.width
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: root.track
                    color: Theme.text
                    font.family: Config.font.family
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: root.artist
                    color: Theme.textDim
                    font.family: Config.font.family
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                spacing: 8
                MediaButton {
                    kind: "prev"
                    size: 12
                    color: Theme.textDim
                    enabled: root.canPrev
                    onClicked: root.prev()
                }
                MediaButton {
                    kind: root.playing ? "pause" : "play"
                    size: 15
                    color: Theme.text
                    onClicked: root.playPause()
                }
                MediaButton {
                    kind: "next"
                    size: 12
                    color: Theme.textDim
                    enabled: root.canNext
                    onClicked: root.next()
                }
            }
        }

        ProgressBar {
            width: parent.width
            value: root.length > 0 ? root.position / root.length : 0
            seekable: root.canSeek
            onSeek: frac => root.seek(frac)
        }
    }
}
