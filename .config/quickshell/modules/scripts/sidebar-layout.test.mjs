// sidebar-layout.test.mjs — run with: node .config/quickshell/modules/scripts/sidebar-layout.test.mjs
import { createRequire } from "module"
const require = createRequire(import.meta.url)
const assert = require("assert")
const { packRows } = require("./sidebar-layout.js")

const rowIds = r => r.cells.map(c => c.id ?? c.type)

// small tiles fill to `columns`, then wrap
{
    const items = [
        { id: "a", size: "small" }, { id: "b", size: "small" },
        { id: "c", size: "small" }, { id: "d", size: "small" },
        { id: "e", size: "small" },
    ]
    const rows = packRows(items, 4)
    assert.deepStrictEqual(rows.map(rowIds), [["a", "b", "c", "d"], ["e"]])
}

// wide takes a full row of its own; a preceding partial row is flushed first
{
    const items = [
        { id: "a", size: "small" },
        { id: "clock", size: "wide" },
        { id: "b", size: "small" },
    ]
    const rows = packRows(items, 4)
    assert.deepStrictEqual(rows.map(rowIds), [["a"], ["clock"], ["b"]])
    assert.strictEqual(rows[1].cells[0].cols, 4)
}

// big spans 2 columns and packs beside smalls
{
    const items = [
        { id: "bat", size: "big" }, { id: "pow", size: "big" },
    ]
    const rows = packRows(items, 4)
    assert.deepStrictEqual(rows.map(rowIds), [["bat", "pow"]])
    assert.strictEqual(rows[0].cells[0].cols, 2)
}

// divider forces its own full-width row and breaks packing
{
    const items = [
        { id: "a", size: "small" }, { type: "divider" }, { id: "b", size: "small" },
    ]
    const rows = packRows(items, 4)
    assert.deepStrictEqual(rows.map(rowIds), [["a"], ["divider"], ["b"]])
}

// spacer forces its own full-width row and breaks packing (like divider)
{
    const items = [
        { id: "a", size: "small" }, { type: "spacer" }, { id: "b", size: "big" },
    ]
    const rows = packRows(items, 4)
    assert.deepStrictEqual(rows.map(rowIds), [["a"], ["spacer"], ["b"]])
    assert.strictEqual(rows[1].cells[0].cols, 4)
}

// unknown size defaults to small; junk items with no id/type are dropped
{
    const items = [{ id: "a" }, { size: "small" }, { id: "b", size: "wat" }]
    const rows = packRows(items, 4)
    assert.deepStrictEqual(rows.map(rowIds), [["a", "b"]])
    assert.strictEqual(rows[0].cells[0].cols, 1)
}

console.log("sidebar-layout.js: all assertions passed")
