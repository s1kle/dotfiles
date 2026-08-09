// sidebar-layout.js — pure row-packer for the sidebar's fixed-column grid.
// packRows(items, columns) -> [{ cells: [{ id?, type?, size, cols }] }]
// small=1 col, wide=full row, big=2 cols, divider=own full-width row.
const SPAN = { small: 1, wide: null, big: 2 } // wide -> full width (resolved to `columns`)

function packRows(items, columns) {
    const rows = []
    let row = []
    let used = 0
    const flush = () => { if (row.length) { rows.push({ cells: row }); row = []; used = 0 } }

    for (const item of items) {
        if (item && item.type === "divider") {
            flush()
            rows.push({ cells: [{ type: "divider", size: "wide", cols: columns }] })
            continue
        }
        if (item && item.type === "spacer") {
            flush()
            rows.push({ cells: [{ type: "spacer", size: "wide", cols: columns }] })
            continue
        }
        if (!item || item.id === undefined) continue // drop junk
        const size = SPAN[item.size] !== undefined ? item.size : "small"
        const cols = size === "wide" ? columns : SPAN[size]
        if (size === "wide") { flush(); rows.push({ cells: [{ id: item.id, size, cols }] }); continue }
        if (used + cols > columns) flush()
        row.push({ id: item.id, size, cols })
        used += cols
    }
    flush()
    return rows
}

// QML ignores this (module is undefined there); Node uses it in the test.
if (typeof module !== "undefined") module.exports = { packRows }
