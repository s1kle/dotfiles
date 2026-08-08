// Ranked substring search shared by the radial menus.
// rank(items, query, keyFn) -> matches ranked (prefix > word-start > substring),
// alphabetical within a tier, sliced to 8. filter() copies, so `items` is never
// reordered. Dual-use: QML imports it as a library; Node requires it for tests.
function rank(items, query, keyFn) {
    const s = (query || "").trim().toLowerCase()
    if (s === "")
        return []
    const tier = name => {
        const n = String(name).toLowerCase()
        if (n.startsWith(s)) return 0
        if (n.split(/\s+/).some(w => w.startsWith(s))) return 1
        return 2
    }
    return items
        .filter(it => String(keyFn(it)).toLowerCase().includes(s))
        .sort((a, b) => tier(keyFn(a)) - tier(keyFn(b)) || String(keyFn(a)).localeCompare(String(keyFn(b))))
        .slice(0, 8)
}

// QML ignores this (module is undefined there); Node uses it in the test.
if (typeof module !== "undefined") module.exports = { rank }
