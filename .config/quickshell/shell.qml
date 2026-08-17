//@ pragma UseQApplication
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

    PowerMenu {}

    ClipboardMenu {}

    TopBar {}

    Sidebar {}

    // Touch SystemTray eagerly at startup (not just when the sidebar rail's
    // Loader first activates) so it claims the StatusNotifierWatcher D-Bus
    // name before other tray clients (nm-applet etc.) start up, look for a
    // watcher, find none, and give up without retrying.
    Component.onCompleted: SystemTray.items

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

    // Commit-only side effects (not preview, which would thrash every app):
    //  - variantProc: light/dark system-wide via the portal (live for GTK4/libadwaita).
    //  - gtkPalette:  exact palette into ~/.config/gtk-4.0/gtk.css (applies on app restart).
    Process { id: variantProc; command: ["sh", "-c", "~/.config/hypr/scripts/theme-variant.sh"] }
    Process { id: gtkPalette;  command: ["sh", "-c", "python3 ~/.config/hypr/scripts/gtk-palette.py"] }

    Connections {
        target: Config
        function onThemeChanged() {
            previewDebounce.stop()
            root.syncKitty()
            variantProc.running = false
            variantProc.running = true
            gtkPalette.running = false
            gtkPalette.running = true
        }
    }
    Connections {
        target: Theme
        function onPreviewNameChanged() { previewDebounce.restart() }
    }
    Timer { id: previewDebounce; interval: 120; onTriggered: root.syncKitty() }
}
