import QtQuick
import QtQuick.Effects

import qs.services

// Center search prompt. Exposes text + the TextInput (for focus). Emits
// navigate(±1) on Up/Down, accepted() on Enter, cancelled() on Escape.
Rectangle {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder: "APP"
    signal navigate(int delta)
    signal accepted()
    signal cancelled()

    implicitWidth: 180
    implicitHeight: 48
    radius: 14
    color: Theme.surface

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#80000000" // black @ 0.5
        blurMax: 24
        shadowBlur: 1.0
        shadowHorizontalOffset: -12
        shadowVerticalOffset: 12
    }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.margins: 12
        horizontalAlignment: TextInput.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        selectionColor: Theme.accent
        clip: true
        font.family: Config.font.family
        font.pixelSize: 14

        Text {
            anchors.centerIn: parent
            visible: input.text === ""
            text: root.placeholder
            color: Theme.textDim
            font.family: Config.font.family
            font.pixelSize: 14
            font.letterSpacing: 14 * 0.12
            font.capitalization: Font.AllUppercase
        }

        Keys.onPressed: e => {
            // toward bottom: Down / Right ; toward top: Up / Left
            if (e.key === Qt.Key_Down || e.key === Qt.Key_Right) { root.navigate(1); e.accepted = true }
            else if (e.key === Qt.Key_Up || e.key === Qt.Key_Left) { root.navigate(-1); e.accepted = true }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.accepted(); e.accepted = true }
            else if (e.key === Qt.Key_Escape) { root.cancelled(); e.accepted = true }
        }
    }
}
