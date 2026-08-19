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

    screen: Quickshell.screens[1] // primary
    color: "transparent"
    anchors { top: true; left: true; right: true }
    implicitHeight: 96
    // reserve only the collapsed pill's strip (top margin + collapsed height);
    // the expanded hover overlays without pushing windows further.
    exclusiveZone: 8 + 34

    // input = the fixed trigger zone (base) unioned with the pill (so an
    // expanded pill wider than the zone still takes clicks). The rest of the
    // strip passes through. Base must be a real, always-valid item — an empty
    // base region masks nothing and even the pill stops responding.
    mask: Region {
        item: hoverZone
        Region { item: pill }
    }

    property bool expanded: false
    readonly property bool hasMusic: Mpris.activePlayer !== null

    // single collapse rule: stay open while EITHER the trigger zone or the pill
    // is hovered, collapse only when both are false. Two independent handlers
    // (one firing unhover while the other is still hovered) is what stuck the
    // island collapsed on a fast pass through the zone.
    function refreshHover() {
        if (zoneHover.hovered || pillHover.hovered) { collapseTimer.stop(); expanded = true }
        else collapseTimer.restart()
    }

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

    function topWidget(id) {
        switch (id) {
            case "clock":   return clockTC
            case "weather": return weatherTC
            case "music":   return musicTC
            default:
                console.warn("TopBar: unknown widget", id)
                return null
        }
    }

    Component {
        id: clockTC
        ClockWidget { time: Time.clockTime; date: Time.longDate }
    }

    Component {
        id: weatherTC
        WeatherWidget {
            morning: win.weatherSlot(Weather.morning)
            now: win.weatherSlot(Weather.now)
            evening: win.weatherSlot(Weather.evening)
        }
    }

    Component {
        id: musicTC
        MusicWidget {
            coverUrl: Mpris.activePlayer ? Mpris.activePlayer.trackArtUrl : ""
            track: Mpris.activePlayer ? Mpris.activePlayer.trackTitle : ""
            artist: Mpris.activePlayer ? Mpris.activePlayer.trackArtist : ""
            playing: Mpris.isPlaying
            canPrev: Mpris.canGoPrevious
            canNext: Mpris.canGoNext
            onPrev: Mpris.previous()
            onNext: Mpris.next()
            onPlayPause: Mpris.togglePlaying()
        }
    }

    // fixed invisible approach trigger centered on the collapsed pill: a cursor
    // thrown into this patch (overshooting the small pill, or landing beside it)
    // expands the island. The pill's own hover keeps it open once expanded, so
    // this only needs to cover the top-edge approach — hence the short height.
    Item {
        id: hoverZone
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        width: 400
        height: 48

        HoverHandler {
            id: zoneHover
            onHoveredChanged: win.refreshHover()
        }
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
            id: pillHover
            onHoveredChanged: win.refreshHover()
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

        // expanded: config-driven rack (Config.topbar.widgets, in order) with
        // separators; `music` auto-hides when there's no player.
        RowLayout {
            id: rack
            anchors.centerIn: parent
            spacing: 18
            // progress² so the rack fades ahead of the (OutBack-front-loaded) width
            // morph — otherwise the pill snaps small while these widgets linger,
            // half-clipped, inside it. Squaring makes them vanish before the
            // collapse looks done (and fade in a touch later on expand).
            opacity: win.progress * win.progress
            enabled: win.expanded // no click/seek on the clipped rack while collapsed

            Repeater {
                model: Config.topbar.widgets
                delegate: RowLayout {
                    required property int index
                    required property var modelData
                    visible: modelData === "music" ? win.hasMusic : true
                    spacing: 18

                    Rectangle {
                        visible: index > 0
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 56
                        color: Theme.primary
                    }
                    Loader {
                        Layout.alignment: Qt.AlignVCenter
                        sourceComponent: win.topWidget(modelData)
                    }
                }
            }
        }
    }

    Timer {
        id: collapseTimer
        interval: Config.topbar.collapseDelay
        onTriggered: win.expanded = false
    }

}
