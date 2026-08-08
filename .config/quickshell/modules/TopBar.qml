import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import qs.services
import qs.widgets

// Top-center dynamic island: collapsed (clock + focused app) springs open on
// hover into a clock | weather | music rack, collapsing again after an idle
// delay. Primary screen only; the input mask keeps clicks passing through the
// transparent strip around the pill.
PanelWindow {
    id: win

    screen: Quickshell.screens[0] // primary
    color: "transparent"
    anchors { top: true; left: true; right: true }
    implicitHeight: 96
    // reserve only the collapsed pill's strip (top margin + collapsed height);
    // the expanded hover overlays without pushing windows further.
    exclusiveZone: 8 + 34

    // only the pill grabs input; the rest of the strip passes through
    mask: Region { item: pill }

    property bool expanded: false
    property real musicPos: 0
    readonly property bool hasMusic: Mpris.activePlayer !== null

    // content-fit widths for each state; the pill animates between them and the
    // content opacity is driven by the pill's *current* width (below), so the
    // widgets fade in exact lockstep with the morph — never lagging behind it.
    readonly property real collapsedW: Math.max(120, collapsedRow.implicitWidth + 32)
    readonly property real expandedW: rack.implicitWidth + 36
    readonly property real progress: (expandedW - collapsedW) > 0
        ? Math.max(0, Math.min(1, (pill.width - collapsedW) / (expandedW - collapsedW)))
        : (expanded ? 1 : 0)

    function weatherSlot(s) {
        return s ? ({ temp: s.temp, icon: Quickshell.shellPath("assets/weather/" + Weather.iconFor(s.code) + ".svg") }) : null
    }

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: 8
        // width fits content in both states (so a long focused-app name or a
        // hidden music widget don't break/overflow the pill).
        width: win.expanded ? win.expandedW : win.collapsedW
        height: win.expanded ? 76 : 34
        radius: 12
        color: Theme.surface
        // clip content to the (animating) pill so widgets don't spill past the
        // edges while the island resizes — e.g. the music rack during collapse.
        clip: true

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#8c000000" // black @ 0.55
            blurMax: 24
            shadowBlur: 1.0
            shadowVerticalOffset: 4
        }

        Behavior on width { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
        Behavior on height { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) { collapseTimer.stop(); win.expanded = true }
                else collapseTimer.restart()
            }
        }

        // collapsed: clock + focused app
        Row {
            id: collapsedRow
            anchors.centerIn: parent
            spacing: 16
            opacity: 1 - win.progress

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Time.clockTime
                color: Theme.text
                font.family: Config.font.family
                font.pixelSize: 12
            }
            FocusedApp {
                anchors.verticalCenter: parent.verticalCenter
                icon: FocusedWindow.icon
                name: FocusedWindow.name
            }
        }

        // expanded: clock | weather | music
        RowLayout {
            id: rack
            anchors.centerIn: parent
            spacing: 18
            opacity: win.progress
            enabled: win.expanded // no click/seek on the clipped rack while collapsed

            ClockWidget {
                Layout.alignment: Qt.AlignVCenter
                time: Time.clockTime
                date: Time.longDate
            }
            Rectangle { Layout.alignment: Qt.AlignVCenter; Layout.preferredWidth: 1; Layout.preferredHeight: 56; color: Theme.primary }
            WeatherWidget {
                Layout.alignment: Qt.AlignVCenter
                morning: win.weatherSlot(Weather.morning)
                now: win.weatherSlot(Weather.now)
                evening: win.weatherSlot(Weather.evening)
            }
            Rectangle { visible: win.hasMusic; Layout.alignment: Qt.AlignVCenter; Layout.preferredWidth: 1; Layout.preferredHeight: 56; color: Theme.primary }
            MusicWidget {
                visible: win.hasMusic
                Layout.alignment: Qt.AlignVCenter
                coverUrl: Mpris.activePlayer ? Mpris.activePlayer.trackArtUrl : ""
                track: Mpris.activePlayer ? Mpris.activePlayer.trackTitle : ""
                artist: Mpris.activePlayer ? Mpris.activePlayer.trackArtist : ""
                playing: Mpris.isPlaying
                canPrev: Mpris.canGoPrevious
                canNext: Mpris.canGoNext
                canSeek: Mpris.activePlayer ? Mpris.activePlayer.canSeek : false
                position: win.musicPos
                length: Mpris.activePlayer ? Mpris.activePlayer.length : 0
                onPrev: Mpris.previous()
                onNext: Mpris.next()
                onPlayPause: Mpris.togglePlaying()
                onSeek: frac => {
                    const p = Mpris.activePlayer
                    if (p && p.canSeek) p.position = frac * p.length
                }
            }
        }
    }

    Timer {
        id: collapseTimer
        interval: Config.topbar.collapseDelay
        onTriggered: win.expanded = false
    }

    // poll music position while the rack is open
    Timer {
        interval: 1000
        running: win.expanded
        repeat: true
        triggeredOnStart: true
        onTriggered: win.musicPos = Mpris.activePlayer ? Mpris.activePlayer.position : 0
    }
}
