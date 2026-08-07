import Quickshell
import Quickshell.Hyprland
import QtQuick

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens

        TopBar {
            required property var modelData
            screen: modelData
        }
    }
}
