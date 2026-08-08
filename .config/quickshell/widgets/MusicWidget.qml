import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

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

    // cover: gradient fallback, real art clipped to a rounded rect on top.
    // ClippingRectangle gives an antialiased rounded clip (a MultiEffect mask
    // pixelated the edges).
    ClippingRectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 48
        height: 48
        radius: 10
        color: "transparent"

        Rectangle {
            anchors.fill: parent
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
        }
    }

    // Item wrapper (writable implicitWidth) so the widget fits its content —
    // track/artist natural width + buttons — capped so a very long title elides
    // instead of stretching the pill open. Drives TopBar's pill width.
    Item {
        id: main
        property int maxWidth: 260
        anchors.verticalCenter: parent.verticalCenter
        // cap off meta's own implicitWidth (a Layout computes it from child
        // hints, independent of allocated width) — referencing inner.implicitWidth
        // instead loops through inner.width → main.width → 0.
        implicitWidth: Math.min(maxWidth, meta.implicitWidth)
        implicitHeight: inner.implicitHeight

        Column {
        id: inner
        width: parent.width
        spacing: 6

        RowLayout {
            id: meta
            width: parent.width
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: root.track
                    color: Theme.text
                    font.family: Config.font.family
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: root.artist
                    color: Theme.textDim
                    font.family: Config.font.family
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                spacing: 6
                Button {
                    text: "Prev"
                    fontSize: 11
                    hpad: 7
                    textColor: Theme.textDim
                    enabled: root.canPrev
                    onClicked: root.prev()
                }
                Button {
                    text: root.playing ? "Pause" : "Play"
                    fontSize: 11
                    hpad: 7
                    textColor: Theme.text
                    onClicked: root.playPause()
                }
                Button {
                    text: "Next"
                    fontSize: 11
                    hpad: 7
                    textColor: Theme.textDim
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
}
