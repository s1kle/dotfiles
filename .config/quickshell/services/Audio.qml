pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property string sinkDescription: sink?.description || sink?.name || "Unknown Device"

    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    property list<PwNode> sinks: []
    property list<PwNode> sources: []

    function setVolume(newVolume: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(100, newVolume));
        }
    }

    function incrementVolume(amount: real): void {
        setVolume(volume + (amount || 5));
    }

    function decrementVolume(amount: real): void {
        setVolume(volume - (amount || 5));
    }

    function toggleMuted(): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = !sink.audio.muted;
        }
    }

    function setSourceVolume(newVolume: real): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(100, newVolume));
        }
    }

    function setAudioSink(newSink: PwNode): void {
        Pipewire.preferredDefaultAudioSink = newSink;
    }

    function setAudioSource(newSource: PwNode): void {
        Pipewire.preferredDefaultAudioSource = newSource;
    }

    function cycleNextAudioOutput(): void {
        if (sinks.length === 0) return;
        const currentIndex = sinks.findIndex(s => s === sink);
        const nextIndex = (currentIndex + 1) % sinks.length;
        setAudioSink(sinks[nextIndex]);
    }

    function refreshNodes(): void {
        const newSinks = [];
        const newSources = [];
        for (const node of Pipewire.nodes.values) {
            if (!node.isStream && node.audio) {
                if (node.isSink) newSinks.push(node);
                else newSources.push(node);
            }
        }
        root.sinks = newSinks;
        root.sources = newSources;
    }

    Component.onCompleted: {
        refreshNodes();
    }

    Connections {
        target: Pipewire.nodes
        function onValuesChanged(): void {
            root.refreshNodes();
        }
    }

    PwObjectTracker {
        objects: [root.sink, root.source, ...root.sinks, ...root.sources].filter(n => n)
    }

    IpcHandler {
        target: "audio"
        function cycleOutput(): void { root.cycleNextAudioOutput(); }
        function toggleMute(): void { root.toggleMuted(); }
        function volumeUp(): void { root.incrementVolume(5); }
        function volumeDown(): void { root.decrementVolume(5); }
    }
}
