import QtQuick
import QtQuick.Effects
import Quickshell.Widgets

import qs.services

Rectangle {
    id: root
    width: 340
    height: 160
    radius: 12
    color: Theme.primary

    readonly property var player: Mpris.activePlayer
    readonly property string artUrl: root.player ? root.player.trackArtUrl : ""
    property real posSec: 0

    function fmt(ms: int): string {
        const s = Math.floor(ms / 1000)
        return `${String(Math.floor(s / 60)).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`
    }

    // ponytail: 1s re-read drives position bindings (MPRIS position may not signal),
    // same approach as end-4/dots-hyprland PlayerControl
    Timer {
        interval: 1000
        repeat: true
        onTriggered: root.posSec = root.player ? root.player.position : 0
    }

    ClippingRectangle {
        id: backdrop
        anchors.fill: parent
        radius: 12
        visible: !!root.artUrl

        Image {
            id: backdropArt
            anchors.fill: parent
            source: root.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize { width: 640; height: 640 }

            layer.enabled: true
            layer.effect: MultiEffect {
                blur: 1.0
                blurMax: 64
                saturation: 0.5
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.primary
            opacity: 0.6
        }
    }

    Rectangle {
        id: artContainer
        x: 12
        y: 12
        width: 136
        height: 136
        radius: 12
        color: Theme.surface
        visible: root.player !== null

        Image {
            anchors.fill: parent
            source: root.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize { width: 320; height: 320 }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.player === null
        text: ":("
        font.family: "Annotation Mono"
        font.pixelSize: 32
        color: Theme.textDim
    }

    Item {
        x: 160
        y: 12
        width: root.width - 160 - 12
        height: 136
        visible: root.player !== null

        Text {
            id: trackTitle
            anchors { top: parent.top; left: parent.left; right: parent.right }
            text: root.player ? (root.player.trackTitle || "Unknown Title") : ""
            font.family: "Annotation Mono"
            font.pixelSize: 14
            color: Theme.text
            elide: Text.ElideRight
        }

        Text {
            id: trackArtist
            anchors { top: trackTitle.bottom; left: parent.left; right: parent.right }
            anchors.topMargin: 2
            text: root.player ? (root.player.trackArtist || "Unknown Artist") : ""
            font.family: "Annotation Mono"
            font.pixelSize: 11
            color: Theme.textDim
            elide: Text.ElideRight
        }

        Item {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 46

            Text {
                anchors { top: parent.top; left: parent.left }
                text: `${root.fmt(root.posSec * 1000)} / ${root.fmt(root.player ? root.player.length * 1000 : 0)}`
                font.family: "Annotation Mono"
                font.pixelSize: 11
                color: Theme.textDim
            }

            Rectangle {
                anchors { top: parent.top; right: parent.right }
                width: 28
                height: 28
                radius: root.player && root.player.isPlaying ? 8 : 14
                color: Theme.surface

                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: root.player && root.player.isPlaying ? "icons/pause.svg" : "icons/play.svg"
                    sourceSize: Qt.size(32, 32)
                    opacity: root.player && root.player.canTogglePlaying ? 1 : 0.3
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.player && root.player.canTogglePlaying
                    onClicked: Mpris.togglePlaying()
                }
            }

            Row {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                spacing: 8

                Item {
                    width: 18
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.fill: parent
                        source: "icons/previous.svg"
                        sourceSize: Qt.size(36, 36)
                        opacity: root.player && root.player.canGoPrevious ? 1 : 0.3
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.player && root.player.canGoPrevious
                        onClicked: Mpris.previous()
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - parent.spacing * 2 - 18 - 18
                    height: 4
                    radius: 2
                    color: Theme.surface

                    Rectangle {
                        width: parent.width * (root.player && root.player.length > 0 ? root.posSec / root.player.length : 0)
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.topMargin: -5
                        anchors.bottomMargin: -5
                        enabled: root.player && root.player.canSeek
                        onClicked: {
                            const p = root.player
                            if (!p || p.length <= 0)
                                return
                            p.position = mouse.x / parent.width * p.length
                        }
                    }
                }

                Item {
                    width: 18
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.fill: parent
                        source: "icons/next.svg"
                        sourceSize: Qt.size(36, 36)
                        opacity: root.player && root.player.canGoNext ? 1 : 0.3
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.player && root.player.canGoNext
                        onClicked: Mpris.next()
                    }
                }
            }
        }
    }
}
