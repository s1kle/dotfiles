import Quickshell
import Quickshell.Io
import QtQuick

import qs.services
import qs.modules

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens

        Notifications {
            required property var modelData
            screen: modelData
        }
    }

    AppMenu {}

    ThemeMenu {}

    TopBar {}

    // Keep kitty's colours in sync with quickshell's theme. The committed theme
    // (Config) applies immediately; the ThemeMenu hover-preview (Theme.previewName)
    // applies debounced so rapid hovering coalesces to the theme you pause on, and
    // reverts to the committed theme when the preview clears (empty previewName).
    function syncKitty() {
        const t = Theme.previewName
        kittyTheme.command = t !== ""
            ? ["sh", "-c", "python3 ~/.config/kitty/sync-theme.py \"$1\"", "sh", t]
            : ["sh", "-c", "python3 ~/.config/kitty/sync-theme.py"]
        kittyTheme.running = false
        kittyTheme.running = true
    }

    Process { id: kittyTheme }

    // Apply the committed theme's variant (dark/light) system-wide (GTK/Qt via
    // the desktop portal). Commit only -- not preview, which would thrash every
    // app's colour scheme on hover.
    Process { id: variantProc; command: ["sh", "-c", "~/.config/hypr/scripts/theme-variant.sh"] }

    Connections {
        target: Config
        function onThemeChanged() {
            previewDebounce.stop()
            root.syncKitty()
            variantProc.running = false
            variantProc.running = true
        }
    }
    Connections {
        target: Theme
        function onPreviewNameChanged() { previewDebounce.restart() }
    }
    Timer { id: previewDebounce; interval: 120; onTriggered: root.syncKitty() }
}
