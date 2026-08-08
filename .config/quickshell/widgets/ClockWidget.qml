import QtQuick

import qs.services

// Dumb: big time over a dim date. Placeholders: time, date.
Column {
    id: root

    property string time: "00:00"
    property string date: ""

    Text {
        text: root.time
        color: Theme.text
        font.family: Config.font.family
        font.pixelSize: 20
    }
    Text {
        text: root.date
        color: Theme.textDim
        font.family: Config.font.family
        font.pixelSize: 11
    }
}
