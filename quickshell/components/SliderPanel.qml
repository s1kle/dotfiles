import QtQuick

import qs.services

// Reusable: a Panel wrapping a muteable Slider. Clicking the title toggles mute —
// value snaps to 0 (title struck through); clicking again restores the previous
// value; dragging the bar un-mutes. value is controlled; moved(v) reports changes.
Panel {
    id: root

    property real value: 0.3
    property bool muted: false
    property real _prev: 0.3
    signal moved(real value)

    width: Config.slider.width
    height: Config.slider.height
    titleInteractive: true
    titleStrikethrough: root.muted

    onTitleClicked: {
        if (root.muted) {
            root.muted = false
            root.moved(root._prev)
        } else {
            root._prev = root.value
            root.muted = true
            root.moved(0)
        }
    }

    Slider {
        width: root.width - 2 * root.padding
        value: root.value
        onMoved: v => {
            root.muted = false
            root.moved(v)
        }
    }
}
