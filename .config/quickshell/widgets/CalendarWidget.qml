import QtQuick

import qs.services

// Current-month grid, today highlighted. Read-only (no prev/next navigation
// in v1 — add if you actually want to browse other months, skip until asked).
Column {
    id: root
    width: parent.width
    spacing: 4

    readonly property date today: new Date()
    readonly property var weeks: {
        const y = today.getFullYear(), m = today.getMonth()
        const first = new Date(y, m, 1)
        const startOffset = (first.getDay() + 6) % 7 // Monday-first grid
        const daysInMonth = new Date(y, m + 1, 0).getDate()
        const cells = []
        for (let i = 0; i < startOffset; i++) cells.push(null)
        for (let d = 1; d <= daysInMonth; d++) cells.push(d)
        while (cells.length % 7 !== 0) cells.push(null)
        const out = []
        for (let i = 0; i < cells.length; i += 7) out.push(cells.slice(i, i + 7))
        return out
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(root.today, "MMMM yyyy")
        color: Theme.text
        font.family: Config.font.family
        font.pixelSize: 13
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4
        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            delegate: Text {
                required property string modelData
                width: 22
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Theme.textDim
                font.family: Config.font.family
                font.pixelSize: 10
            }
        }
    }

    Repeater {
        model: root.weeks
        delegate: Row {
            required property var modelData
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            Repeater {
                model: parent.modelData
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool isToday: modelData === root.today.getDate()
                    width: 22; height: 22
                    radius: 11
                    color: isToday ? Theme.accent : "transparent"
                    Text {
                        anchors.centerIn: parent
                        visible: parent.modelData !== null
                        text: parent.modelData ?? ""
                        color: parent.isToday ? Theme.background : Theme.textDim
                        font.family: Config.font.family
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
