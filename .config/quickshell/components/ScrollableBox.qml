import QtQuick

import qs.services

// Interaction wrapper: hover + wheel/touchpad scroll steps `value`; left-click
// (or Enter, via activated()) opens config; right-click toggles. Dumb — the
// consumer binds `value` and reacts to moved/activated/toggled by calling a
// service. `selected` is the keyboard-selection flag (drawn by the parent tile).
Item {
    id: root

    property real value: 0
    property real step: Config.sidebar.scrollStep
    property bool selected: false
    property bool scrollable: true
    signal moved(real value)
    signal activated()
    signal toggled()

    default property alias content: slot.data

    function stepUp(): void { if (root.scrollable) root.moved(Math.min(1, root.value + root.step)) }
    function stepDown(): void { if (root.scrollable) root.moved(Math.max(0, root.value - root.step)) }

    // sized by the consumer (anchors.fill); no implicit size so a fills-parent
    // slot can't feed back into it as a binding loop.
    Item { id: slot; anchors.fill: parent }

    WheelHandler {
        enabled: root.scrollable
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (event.angleDelta.y > 0) root.stepUp()
            else if (event.angleDelta.y < 0) root.stepDown()
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (point, button) => {
            if (button === Qt.RightButton) root.toggled()
            else root.activated()
        }
    }
}
