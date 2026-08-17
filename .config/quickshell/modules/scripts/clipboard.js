// clipboard.js — parses `cliphist list` output and filters entries for the
// ClipboardMenu picker. Dual-use: QML imports it as a library; Node requires
// it for the test. `rank` is injected, not required here — QML's JS engine
// has no require(), only ".qml files can `import x.js as Y`", so cross-script
// reuse has to be dependency-injected rather than nested-required.
function parseList(text) {
    return (text || "").split("\n")
        .filter(line => line.trim() !== "")
        .map(line => {
            const i = line.indexOf("\t")
            if (i < 0) return null
            // a trailing \r survives here when cliphist's output uses CRLF
            // and the caller only split on \n; strip stray \r/\n so nothing
            // sneaks a second visual line into a fixed-height list row.
            const preview = line.slice(i + 1).replace(/[\r\n]+/g, " ").trim()
            return { id: line.slice(0, i), preview }
        })
        .filter(Boolean)
}

// empty query -> first 20 entries in cliphist's own (most-recent-first) order;
// non-empty query -> rankFn's ranked substring match (pass search.js's rank).
function filterEntries(entries, query, rankFn) {
    const q = (query || "").trim()
    if (q === "") return entries.slice(0, 20)
    return rankFn(entries, q, e => e.preview)
}

// cliphist's own marker for binary (image) entries: "[[ binary data ... ]]".
function isImage(entry) {
    return /^\[\[ binary data/.test(entry.preview)
}

if (typeof module !== "undefined") module.exports = { parseList, filterEntries, isImage }
