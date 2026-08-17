// clipboard.test.mjs — run with: node .config/quickshell/modules/scripts/clipboard.test.mjs
import { createRequire } from "module"
const require = createRequire(import.meta.url)
const assert = require("assert")
const { parseList, filterEntries, isImage } = require("./clipboard.js")
const { rank } = require("./search.js")

// parses tab-separated "id\tpreview" lines, skips blanks
{
    const text = "1\thello world\n\n2\tsecond entry\n"
    assert.deepStrictEqual(parseList(text), [
        { id: "1", preview: "hello world" },
        { id: "2", preview: "second entry" },
    ])
}

// line with no tab is dropped
assert.deepStrictEqual(parseList("no-tab-here"), [])

// a trailing \r (CRLF line ending) is stripped so it can't paint a second
// visual line in a fixed-height list row
assert.deepStrictEqual(parseList("9\tsome preview\r"), [
    { id: "9", preview: "some preview" },
])

// empty query -> first 20 entries as-is, in input order
{
    const entries = Array.from({ length: 25 }, (_, i) => ({ id: String(i), preview: "item" + i }))
    assert.strictEqual(filterEntries(entries, "", rank).length, 20)
    assert.strictEqual(filterEntries(entries, "", rank)[0].id, "0")
}

// non-empty query -> ranked substring match over preview text
{
    const entries = [{ id: "1", preview: "Zen Browser" }, { id: "2", preview: "CMake config" }]
    const matches = filterEntries(entries, "cmake", rank)
    assert.strictEqual(matches.length, 1)
    assert.strictEqual(matches[0].id, "2")
}

// image entries are cliphist's "[[ binary data ... ]]" marker
assert.strictEqual(isImage({ preview: "[[ binary data 12345 png 1920x1080 ]]" }), true)
assert.strictEqual(isImage({ preview: "plain text" }), false)

console.log("clipboard.js: all assertions passed")
