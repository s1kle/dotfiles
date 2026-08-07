pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string currentTheme: Config.theme.name

    property color background
    property color surface
    property color primary
    property color secondary
    property color accent
    property color accentHover
    property color accentMuted
    property color text
    property color textDim

    function loadColors(text: string): void {
        try {
            const data = JSON.parse(text)
            for (const key of Object.keys(data)) {
                if (root[key] !== undefined) {
                    root[key] = data[key]
                }
            }
        } catch (e) {
            console.warn(`Theme: failed to parse ${root.currentTheme}.json: ${e?.message ?? e}`)
        }
    }

    FileView {
        id: themeFile
        path: Quickshell.shellPath(`themes/${root.currentTheme}.json`)
        watchChanges: true
        onLoaded: root.loadColors(text())
        onFileChanged: root.loadColors(text())
        onLoadFailed: err => console.warn(`Theme: ${root.currentTheme}.json not loaded: ${FileViewError.toString(err)}`)
    }
}
