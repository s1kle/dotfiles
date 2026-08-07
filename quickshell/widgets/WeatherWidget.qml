import Quickshell.Io
import QtQuick

import qs.services

Rectangle {
    id: root
    width: 160
    height: 160
    radius: 12
    color: Theme.primary

    property string city: "Приморский край, Находка"
    property string condition: ""
    property string temp: ""
    property string feelsLike: ""

    function refresh() {
        const url = `https://wttr.in/${encodeURIComponent(root.city)}?format=%C|%t|%f`
        weatherProc.exec(["curl", "-s", "--max-time", "10", url])
    }

    Process {
        id: weatherProc
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|")
                if (parts.length >= 3) {
                    root.condition = parts[0]
                    root.temp = parts[1]
                    root.feelsLike = parts[2]
                }
            }
        }
    }

    Timer {
        interval: 600000
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    Column {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 4

        Text {
            text: root.condition
            font.family: "Annotation Mono"
            font.pixelSize: 13
            color: Theme.textDim
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: root.temp
            font.family: "Annotation Mono"
            font.pixelSize: 32
            color: Theme.text
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: root.feelsLike ? `feels like ${root.feelsLike}` : ""
            font.family: "Annotation Mono"
            font.pixelSize: 11
            color: Theme.textDim
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
