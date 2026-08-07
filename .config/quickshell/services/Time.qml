pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    property string time: Qt.formatDateTime(clock.date, "hh:mm")
    property string date: Qt.formatDateTime(clock.date, "ddd dd.MM.yyyy")

    SystemClock { id: clock; precision: SystemClock.Minutes }
}
