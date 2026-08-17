import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import qs.services
import "scripts/clipboard.js" as Clip
import "scripts/search.js" as Search

// Clipboard-history picker: filter-as-you-type vertical list over
// `cliphist list` (not radial — clipboard entries are text, a compass fan
// doesn't fit). Enter/click copies the entry back via `cliphist decode |
// wl-copy`. IPC: qs ipc call clipboard toggle
PanelWindow {
    id: win

    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    focusable: true
    exclusiveZone: 0

    property var entries: []
    property var results: Clip.filterEntries(win.entries, searchInput.text, Search.rank)
    property int selected: 0

    function open(): void {
        win.visible = true
        listProc.exec(["cliphist", "list"])
        searchInput.text = ""
        searchInput.forceActiveFocus()
    }
    function close(): void { win.visible = false }
    function toggle(): void { win.visible ? win.close() : win.open() }
    function moveSelection(d: int): void {
        if (win.results.length > 0)
            win.selected = (win.selected + d + win.results.length) % win.results.length
    }

    Process {
        id: listProc
        stdout: StdioCollector { onStreamFinished: win.entries = Clip.parseList(text) }
    }

    function commitSelected(): void {
        const e = win.results[win.selected]
        if (!e) return
        win.close()
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", e.id])
    }

    onResultsChanged: win.selected = 0

    IpcHandler {
        target: "clipboard"
        function toggle(): void { win.toggle() }
        function open(): void { win.open() }
        function close(): void { win.close() }
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: 420
        height: 420
        radius: 16
        color: Theme.surface
        border.width: 1
        border.color: Theme.accentMuted

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#80000000" // black @ 0.5
            blurMax: 24
            shadowBlur: 1.0
            shadowHorizontalOffset: -12
            shadowVerticalOffset: 12
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // inline search — a bordered box inset into the panel, not a
            // separate floating widget (unlike Search.qml's pill, used by
            // AppMenu/ThemeMenu, which stays as-is for those).
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 10
                color: Theme.background
                border.width: 1
                border.color: Theme.accentMuted

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.margins: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    selectionColor: Theme.accent
                    clip: true
                    font.family: Config.font.family
                    font.pixelSize: 13

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: searchInput.text === ""
                        text: "SEARCH CLIPBOARD"
                        color: Theme.textDim
                        font.family: Config.font.family
                        font.pixelSize: 13
                        font.letterSpacing: 13 * 0.08
                    }

                    Keys.onPressed: e => {
                        if (e.key === Qt.Key_Down) { win.moveSelection(1); e.accepted = true }
                        else if (e.key === Qt.Key_Up) { win.moveSelection(-1); e.accepted = true }
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { win.commitSelected(); e.accepted = true }
                        else if (e.key === Qt.Key_Escape) { win.close(); e.accepted = true }
                    }
                }
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: win.results
                currentIndex: win.selected

                // mouse wheel steps the selection (like the sidebar's scroll
                // tiles) and keeps it scrolled into view.
                WheelHandler {
                    onWheel: event => {
                        win.moveSelection(event.angleDelta.y > 0 ? -1 : 1)
                        listView.positionViewAtIndex(win.selected, ListView.Contain)
                    }
                }

                delegate: Item {
                    id: row
                    required property int index
                    required property var modelData
                    // never let a row's content (a long/odd preview string,
                    // an image still settling into its computed height)
                    // paint past its own bounds into the row below it.
                    clip: true
                    readonly property bool isImage: Clip.isImage(modelData)
                    // ponytail: decoded thumbnails land in /tmp and are never
                    // cleaned up — /tmp is cleared on reboot and entry counts
                    // here are small, so not worth a cleanup pass yet.
                    readonly property string thumbPath: "/tmp/qs-clip-" + modelData.id + ".img"
                    property bool thumbReady: false

                    width: ListView.view.width
                    readonly property real availWidth: row.width - 12
                    // full-width, aspect-ratio-preserving height once the
                    // image's natural size is known; a placeholder height
                    // while it's still decoding/loading. img.width/height
                    // below are bound to this SAME value (not left to
                    // fillMode auto-sizing from natural pixel size), so the
                    // row never has to clip the image to fit it.
                    readonly property real imgHeight:
                        (img.status === Image.Ready && img.implicitWidth > 0)
                            ? row.availWidth * img.implicitHeight / img.implicitWidth
                            : 160
                    height: row.isImage ? row.imgHeight + 12 : 36

                    Component.onCompleted: {
                        if (row.isImage)
                            thumbProc.exec(["sh", "-c", 'cliphist decode "$1" > "$2"', "sh", modelData.id, row.thumbPath])
                    }
                    Process { id: thumbProc; onExited: row.thumbReady = true }

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: row.index === win.selected ? Theme.secondary : "transparent"
                    }

                    Image {
                        id: img
                        visible: row.isImage
                        anchors { left: parent.left; top: parent.top; margins: 6 }
                        width: row.isImage ? row.availWidth : 0
                        height: row.isImage ? row.imgHeight : 0
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        source: row.thumbReady ? "file://" + row.thumbPath : ""
                    }

                    Text {
                        visible: !row.isImage
                        anchors.fill: parent
                        anchors.margins: 8
                        verticalAlignment: Text.AlignVCenter
                        text: modelData.preview
                        color: Theme.text
                        font.family: Config.font.family
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    TapHandler { onTapped: { win.selected = row.index; win.commitSelected() } }
                }
            }
        }
    }
}
