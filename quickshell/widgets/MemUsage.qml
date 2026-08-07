import qs.components

// Dumb gauge: memory usage ring. value is 0..1 (placeholder); wired in a module.
Panel {
    id: root
    property real value: 0.3
    title: "MEM"

    Progress { value: root.value }
}
