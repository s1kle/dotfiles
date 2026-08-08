// search.test.mjs — run with: node .config/quickshell/modules/scripts/search.test.mjs
import { createRequire } from "module"
const require = createRequire(import.meta.url)
const assert = require("assert")
const { rank } = require("./search.js")

const items = [
    { name: "Zen Browser" },
    { name: "Обозреватель Avahi Zeroconf" },
    { name: "CMake" },
    { name: "Wallpaper Engine" },
]
const key = it => it.name

// empty query -> nothing
assert.deepStrictEqual(rank(items, "", key), [])
assert.deepStrictEqual(rank(items, "   ", key), [])

// prefix beats mid-word: "ze" -> Zen (prefix) before the Zeroconf substring
const ze = rank(items, "ze", key).map(key)
assert.strictEqual(ze[0], "Zen Browser", `expected Zen first, got ${ze}`)
assert.ok(ze.includes("Обозреватель Avahi Zeroconf"))

// case-insensitive + substring
assert.deepStrictEqual(rank(items, "CMAKE", key).map(key), ["CMake"])

// does not mutate input order
const before = items.map(key).join("|")
rank(items, "e", key)
assert.strictEqual(items.map(key).join("|"), before)

// caps at 8
const many = Array.from({ length: 20 }, (_, i) => ({ name: "app" + i }))
assert.strictEqual(rank(many, "app", it => it.name).length, 8)

console.log("search.js: all assertions passed")
