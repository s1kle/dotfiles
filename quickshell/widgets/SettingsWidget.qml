import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

import qs.services

Rectangle {
    id: root
    width: 240
    height: 75
    radius: 12
    color: Theme.primary

    property bool active: true

    PwObjectTracker {
        id: micTracker
        objects: [Pipewire.defaultAudioSource]
    }

    readonly property var micNode: micTracker.objects.length > 0 ? micTracker.objects[0] : null

    Column {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        anchors.margins: 10
        spacing: 9

        Row {
            spacing: 4

            Text {
                text: "MIC:"
                font.family: "Annotation Mono"
                font.pixelSize: 13
                color: Theme.text
                width: 30
                anchors.verticalCenter: parent.verticalCenter
            }

            SliderTrack {
                value: root.micNode ? root.micNode.volume : 0
                enabled: root.micNode !== null
                onUserSet: v => {
                    if (root.micNode)
                        root.micNode.volume = v
                }
            }
        }

        Row {
            spacing: 4

            Text {
                text: "BRI:"
                font.family: "Annotation Mono"
                font.pixelSize: 13
                color: Theme.text
                width: 30
                anchors.verticalCenter: parent.verticalCenter
            }

            SliderTrack {
                id: briTrack
                value: root.briValue
                enabled: root.briAvailable
                onUserSet: v => root.setBrightness(v)
            }
        }
    }

    property bool briAvailable: false
    property real briValue: 0

    Process {
        id: briProc
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                if (parts.length >= 4) {
                    const max = parseFloat(parts[3])
                    const cur = parseFloat(parts[2])
                    if (max > 0 && !isNaN(cur)) {
                        root.briAvailable = true
                        root.briValue = Math.max(0, Math.min(1, cur / max))
                    }
                }
            }
        }
    }

    function setBrightness(v: real) {
        root.briValue = v
        briProc.exec(["brightnessctl", "-q", "set", `${Math.round(v * 100)}%`])
    }

    function refreshBrightness() {
        briProc.exec(["brightnessctl", "-m", "get"])
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.active
        onTriggered: root.refreshBrightness()
    }

    Component.onCompleted: root.refreshBrightness()

    component SliderTrack: Item {
        id: track
        property real value: 0
        property bool enabled: true
        signal userSet(real value)

        width: 180
        height: 16

        Rectangle {
            radius: 8
            width: parent.width
            height: parent.height
            color: Theme.secondary
        }

        Rectangle {
            radius: 8
            width: parent.width * track.value
            height: parent.height
            color: Theme.accent
            opacity: track.enabled ? 1 : 0.35
        }

        MouseArea {
            anchors.fill: parent
            enabled: track.enabled
            onPressed: m => track.handle(m.x)
            onPositionChanged: m => track.handle(m.x)
        }

        function handle(mx: real) {
            track.value = Math.max(0, Math.min(1, mx / track.width))
            track.userSet(track.value)
        }
    }
}
