import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.components
import qs.services

// Dumb: a notification card — appName (title), body text, optional image.
// All placeholder defaults; real data is wired in a module.
NotificationPanel {
    id: root

    property string appName: "DISCORD"
    property string body: "Alex sent you a message in #general"
    property string image: ""

    title: root.appName

    Text {
        Layout.fillWidth: true
        text: root.body
        color: Theme.text
        font.family: Config.font.family
        font.pixelSize: 13
        lineHeight: 1.4
        wrapMode: Text.WordWrap
    }

    ClippingRectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        Layout.topMargin: 2
        radius: 10
        color: Theme.primary
        visible: root.image !== ""

        Image {
            anchors.fill: parent
            source: root.image
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }
}
