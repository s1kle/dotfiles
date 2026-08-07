import Quickshell
import QtQuick

import qs.services
import qs.widgets

PanelWindow {
    id: win

    color: "transparent"
    anchors.top: true
    exclusiveZone: 34
    implicitWidth: 800
    implicitHeight: 180
    mask: Region { x: 0; y: 0; width: 800; height: 180 }

    property bool hovered: false

    Rectangle {
        id: bar
        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
        width: win.hovered ? 800 : clockText.implicitWidth + 16
        height: win.hovered ? 180 : 34
        radius: 12
        color: Theme.surface

        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 12
            color: Theme.surface
        }

        Row {
            id: collapsed
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }
            width: parent.width
            height: 34
            leftPadding: 8
            rightPadding: 8
            opacity: win.hovered ? 0 : 1

            Behavior on opacity { NumberAnimation { duration: 100 } }

            Text {
                id: clockText
                text: Time.time
                font.family: "Annotation Mono"
                font.pixelSize: 13
                color: Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        WeatherWidget {
            x: 10
            y: win.hovered ? 10 : -160
            opacity: win.hovered ? 1 : 0

            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        MusicWidget {
            x: bar.width - 10 - width
            y: win.hovered ? 10 : -160
            opacity: win.hovered ? 1 : 0

            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        WorkspacesWidget {
            monitorIndex: 0
            x: 180
            y: win.hovered ? 10 : -80
            opacity: win.hovered ? 1 : 0

            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        WorkspacesWidget {
            monitorIndex: 1
            x: 305
            y: win.hovered ? 10 : -80
            opacity: win.hovered ? 1 : 0

            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        SettingsWidget {
            active: win.hovered
            x: 180
            y: win.hovered ? 95 : -80
            opacity: win.hovered ? 1 : 0

            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: win.hovered = true
            onExited: win.hovered = false
        }
    }
}
