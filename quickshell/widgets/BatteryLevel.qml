import qs.components

// Dumb gauge: battery level ring. value is 0..1 (placeholder); wired in a module.
Panel {
    id: root
    property real value: 0.3
    title: "BAT"

    Progress { value: root.value }
}
