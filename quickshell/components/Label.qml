import QtQuick

import qs.services

// Plain panel label: uppercase, letter-spaced, dim. Not interactive.
Text {
    property bool strikethrough: false

    color: Theme.textDim
    font.family: Config.font.family
    font.pixelSize: 11
    font.weight: Font.DemiBold
    font.letterSpacing: 11 * 0.12 // 0.12em
    font.capitalization: Font.AllUppercase
    font.strikeout: strikethrough
}
