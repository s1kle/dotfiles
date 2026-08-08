import Quickshell
import QtQuick

import qs.modules

ShellRoot {
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
}
