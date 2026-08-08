pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel

// Theme registry: auto-discovers themes/*.json and exposes { name, variant,
// palette }. Dropping a new theme file in makes it appear.
Singleton {
    id: root

    property var list: []

    FolderListModel {
        id: folder
        folder: Qt.resolvedUrl(Quickshell.shellPath("themes"))
        nameFilters: ["*.json"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    // One block-loading FileView per theme file; rebuild the list as files
    // appear/disappear. blockLoading makes text() available immediately.
    Instantiator {
        id: inst
        model: folder
        delegate: FileView {
            required property string fileName
            path: Quickshell.shellPath("themes/" + fileName)
            blockLoading: true
        }
        onObjectAdded: root.rebuild()
        onObjectRemoved: root.rebuild()
    }

    function rebuild(): void {
        const out = []
        for (let i = 0; i < inst.count; i++) {
            const fv = inst.objectAt(i)
            if (!fv) continue
            try {
                const j = JSON.parse(fv.text())
                out.push({
                    name: String(fv.fileName).replace(/\.json$/, ""),
                    variant: j.variant || "dark",
                    palette: j
                })
            } catch (e) {
                console.warn(`Themes: failed to parse ${fv.fileName}: ${e?.message ?? e}`)
            }
        }
        out.sort((a, b) => a.name.localeCompare(b.name))
        root.list = out
    }
}
