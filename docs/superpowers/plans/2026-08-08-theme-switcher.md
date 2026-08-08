# Radial Theme Switcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a radial theme switcher to the Quickshell shell — browse themes, live-preview on hover, commit on Enter/click — reusing the app-menu's search logic.

**Architecture:** Extract the app-menu's ranked search into a shared JS helper (`modules/scripts/search.js`). A new `Themes` service auto-discovers `themes/*.json` (name + variant + palette). `Theme` gains a `previewName` override so hover recolors the whole shell live. A new `ThemeMenu` module clones AppMenu's radial layout with 2-line palette entries, `@dark`/`@light` alias parsing, and commit-to-`config.json`.

**Tech Stack:** Quickshell 0.3.0 / Qt 6.11 QML, `Qt.labs.folderlistmodel`, plain JS. No unit-test framework in-repo; the one pure-logic unit (`search.js`) gets a Node assert check, everything QML is verified by deploying to the Hyprland VM and visual sign-off.

## Global Constraints

- **Runs only on a Hyprland host.** Cannot run on this WSL box. Deploy + verify on VM `test@192.168.31.218` per `CLAUDE.md` (rsync `.config/quickshell/`, relaunch `qs-bar` transient unit, `journalctl --user -u qs-bar` for errors, ignore libEGL/MESA/ZINK/dri2 noise).
- **Branch:** work on `theme-switcher` (already created off `quickshell`). Commit per task. At the end: rebase onto `quickshell`, merge to `main`.
- **Never commit** `index.html`, `style.css`, or the dangling `docs/superpowers/*config-service*` deletions.
- **QML gotchas** (from `CLAUDE.md`): object-literal property needs parens `property var x: ({...})`; `FileView` hot-reload needs `onFileChanged: reload()`; no object spread / use `Object.assign`/`concat`; `Quickshell.iconPath(name,true)` returns `""` for missing; signal handlers use arrow fns with formal params.
- **After Task 1, STOP for an explicit user checkpoint** verifying AppMenu still works before building the switcher.
- **Theme JSON schema:** the 9 existing color keys (`background, surface, primary, secondary, accent, accentHover, accentMuted, text, textDim`) plus new `"variant": "dark"|"light"`.

---

### Task 1: Extract reusable ranked search + refactor AppMenu

**Files:**
- Create: `.config/quickshell/modules/scripts/search.js`
- Create: `.config/quickshell/modules/scripts/search.test.mjs` (Node check, dev-only)
- Modify: `.config/quickshell/modules/AppMenu.qml` (the `filterApps` function, ~lines 37-53)

**Interfaces:**
- Produces: `rank(items: Array, query: string, keyFn: (item)=>string) : Array` — filters `items` to those whose key contains the (lowercased, trimmed) query, sorted by tier (0 name-prefix, 1 word-start, 2 substring) then alphabetical, sliced to 8. Empty/whitespace query → `[]`. Does not mutate `items`.

- [ ] **Step 1: Write `search.js`**

```js
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
```

- [ ] **Step 2: Write the failing test**

```js
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
```

- [ ] **Step 3: Run test, expect FAIL**

Run: `node .config/quickshell/modules/scripts/search.test.mjs`
Expected first run (before `search.js` exists / if broken): FAIL (module not found or assertion). After Step 1 it should PASS — if it fails, fix `search.js`.

- [ ] **Step 4: Run test, expect PASS**

Run: `node .config/quickshell/modules/scripts/search.test.mjs`
Expected: `search.js: all assertions passed`

- [ ] **Step 5: Refactor AppMenu to use it**

In `AppMenu.qml`, add near the top imports:
```qml
import "scripts/search.js" as Search
```
Replace the whole `filterApps` function body with:
```qml
    function filterApps(q: string): var {
        return Search.rank(Apps.list, q, a => a.name)
    }
```
(Delete the now-duplicated inline `rank`/tier logic and its comment.)

- [ ] **Step 6: Deploy to VM and check it starts clean**

```bash
rsync -a --delete .config/quickshell/ test@192.168.31.218:~/.config/quickshell/
ssh test@192.168.31.218 'export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
  export HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr/ | head -1)
  pkill -x quickshell; systemctl --user stop qs-bar 2>/dev/null; systemctl --user reset-failed qs-bar 2>/dev/null
  systemd-run --user --collect --unit=qs-bar --setenv=HYPRLAND_INSTANCE_SIGNATURE="$HYPRLAND_INSTANCE_SIGNATURE" --setenv=WAYLAND_DISPLAY=wayland-1 --setenv=XDG_RUNTIME_DIR=/run/user/1000 quickshell -p ~/.config/quickshell/shell.qml
  sleep 1; systemctl --user is-active qs-bar'
```
Expected: `active`, no QML errors in `journalctl --user -u qs-bar` (ignore libEGL/MESA/ZINK noise). `.mjs` test file is NOT synced into the shell in a way that breaks it (it's inert; harmless if present).

- [ ] **Step 7: USER CHECKPOINT — verify AppMenu**

Ask the user to `qs ipc call appmenu toggle` and confirm: results still filter as before, "ze" ranks Zen first, launching works. **Do not proceed until confirmed.**

- [ ] **Step 8: Commit**

```bash
git add .config/quickshell/modules/scripts/search.js .config/quickshell/modules/scripts/search.test.mjs .config/quickshell/modules/AppMenu.qml
git commit -m "refactor(appmenu): extract ranked search to modules/scripts/search.js

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 2: `Search` component gains a `placeholder` property

**Files:**
- Modify: `.config/quickshell/components/Search.qml` (placeholder Text ~line 47)

**Interfaces:**
- Produces: `Search { placeholder: string }` — default `"APP"`; shown centered/dim when text is empty.

- [ ] **Step 1: Add the property and bind it**

In `Search.qml`, add to the root's properties (near `property alias text`):
```qml
    property string placeholder: "APP"
```
Change the placeholder `Text { ... text: "APP" ... }` to:
```qml
            text: root.placeholder
```

- [ ] **Step 2: Keep AppMenu's placeholder explicit**

In `AppMenu.qml`, set it on the `Search` instance (self-documenting, unchanged behavior):
```qml
    Search {
        id: search
        placeholder: "APP"
        anchors.centerIn: parent
        ...
```

- [ ] **Step 3: Deploy + verify starts clean** (rsync + relaunch as in Task 1 Step 6). AppMenu placeholder still reads "APP".

- [ ] **Step 4: Commit**

```bash
git add .config/quickshell/components/Search.qml .config/quickshell/modules/AppMenu.qml
git commit -m "feat(search): configurable placeholder text

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 3: Tag existing themes + add 6 popular themes

**Files:**
- Modify: `.config/quickshell/themes/NordTheme.json`, `.config/quickshell/themes/CatppuccinMocha.json` (add `"variant"`)
- Create: `.config/quickshell/themes/GruvboxDark.json`, `TokyoNight.json`, `Dracula.json` (variant `dark`)
- Create: `.config/quickshell/themes/CatppuccinLatte.json`, `GruvboxLight.json`, `RosePineDawn.json` (variant `light`)

**Interfaces:**
- Produces: 8 theme files, each with the 9 color keys + `"variant"`. Consumed by `Themes` (Task 4).

- [ ] **Step 1: Add `variant` to the two existing files**

Add `"variant": "dark",` as the first key in both `NordTheme.json` and `CatppuccinMocha.json`.

- [ ] **Step 2: Create the 6 new theme files**

Use the same 9-key schema + `variant`. Map each palette to the roles:
`background`=base bg, `surface`=raised panel, `primary`=slightly-raised, `secondary`=muted mid, `accent`=main accent, `accentHover`=lighter accent, `accentMuted`=dim accent/ring, `text`=fg, `textDim`=muted fg.

`GruvboxDark.json`:
```json
{
  "variant": "dark",
  "background": "#282828",
  "surface": "#3c3836",
  "primary": "#504945",
  "secondary": "#665c54",
  "accent": "#fabd2f",
  "accentHover": "#fe8019",
  "accentMuted": "#4d4030",
  "text": "#ebdbb2",
  "textDim": "#a89984"
}
```
`TokyoNight.json`:
```json
{
  "variant": "dark",
  "background": "#1a1b26",
  "surface": "#24283b",
  "primary": "#2f334d",
  "secondary": "#414868",
  "accent": "#7aa2f7",
  "accentHover": "#89b4ff",
  "accentMuted": "#2a2f45",
  "text": "#c0caf5",
  "textDim": "#565f89"
}
```
`Dracula.json`:
```json
{
  "variant": "dark",
  "background": "#282a36",
  "surface": "#343746",
  "primary": "#424450",
  "secondary": "#6272a4",
  "accent": "#bd93f9",
  "accentHover": "#ff79c6",
  "accentMuted": "#3a3546",
  "text": "#f8f8f2",
  "textDim": "#8a8ea8"
}
```
`CatppuccinLatte.json`:
```json
{
  "variant": "light",
  "background": "#eff1f5",
  "surface": "#e6e9ef",
  "primary": "#dce0e8",
  "secondary": "#bcc0cc",
  "accent": "#1e66f5",
  "accentHover": "#7287fd",
  "accentMuted": "#ccd0da",
  "text": "#4c4f69",
  "textDim": "#8c8fa1"
}
```
`GruvboxLight.json`:
```json
{
  "variant": "light",
  "background": "#fbf1c7",
  "surface": "#f2e5bc",
  "primary": "#ebdbb2",
  "secondary": "#d5c4a1",
  "accent": "#d65d0e",
  "accentHover": "#af3a03",
  "accentMuted": "#e8dab2",
  "text": "#3c3836",
  "textDim": "#7c6f64"
}
```
`RosePineDawn.json`:
```json
{
  "variant": "light",
  "background": "#faf4ed",
  "surface": "#fffaf3",
  "primary": "#f2e9e1",
  "secondary": "#dfdad9",
  "accent": "#d7827e",
  "accentHover": "#b4637a",
  "accentMuted": "#f4ede8",
  "text": "#575279",
  "textDim": "#9893a5"
}
```

- [ ] **Step 3: Validate JSON**

Run: `for f in .config/quickshell/themes/*.json; do node -e "JSON.parse(require('fs').readFileSync('$f'))" && echo "ok $f" || echo "BAD $f"; done`
Expected: `ok` for all 8.

- [ ] **Step 4: Commit**

```bash
git add .config/quickshell/themes/
git commit -m "feat(themes): tag variants and add 6 popular themes (3 dark, 3 light)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 4: `Themes` service (auto-discover name/variant/palette)

**Files:**
- Create: `.config/quickshell/services/Themes.qml`
- Modify: `.config/quickshell/services/qmldir` (register `Themes`)

**Interfaces:**
- Produces: `Themes.list : Array<{ name: string, variant: string, palette: object }>` sorted by `name`. `palette` is the parsed theme JSON (9 color keys + variant). Consumed by ThemeMenu (Task 8) and ThemeEntry (Task 7).

- [ ] **Step 1: Write the service**

```qml
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel

// Theme registry: auto-discovers themes/*.json and exposes { name, variant,
// palette }. Dropping a new theme file in makes it appear.
Singleton {
    id: root

    property var list: []

    FolderListModel {
        id: folder
        folder: Quickshell.shellPath("themes")
        nameFilters: ["*.json"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    // One block-loading FileView per theme file; rebuild the list as files
    // appear/disappear. blockLoading makes text() available immediately.
    Instantiator {
        id: inst
        model: folder
        delegate: FileView {
            required property string fileName
            path: Quickshell.shellPath("themes/" + fileName)
            blockLoading: true
        }
        onObjectAdded: root.rebuild()
        onObjectRemoved: root.rebuild()
    }

    function rebuild(): void {
        const out = []
        for (let i = 0; i < inst.count; i++) {
            const fv = inst.objectAt(i)
            if (!fv) continue
            try {
                const j = JSON.parse(fv.text())
                out.push({
                    name: String(fv.fileName).replace(/\.json$/, ""),
                    variant: j.variant || "dark",
                    palette: j
                })
            } catch (e) {
                console.warn(`Themes: failed to parse ${fv.fileName}: ${e?.message ?? e}`)
            }
        }
        out.sort((a, b) => a.name.localeCompare(b.name))
        root.list = out
    }
}
```

- [ ] **Step 2: Register in qmldir**

Add to `.config/quickshell/services/qmldir`:
```
singleton Themes 1.0 Themes.qml
```
(Match the existing line format in that file.)

- [ ] **Step 3: Deploy + verify starts clean** (rsync + relaunch). No parse warnings for the 8 themes in `journalctl`. (Nothing visible yet — service only.)

- [ ] **Step 4: Commit**

```bash
git add .config/quickshell/services/Themes.qml .config/quickshell/services/qmldir
git commit -m "feat(services): Themes — auto-discover theme files (name/variant/palette)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 5: `Theme` live-preview override

**Files:**
- Modify: `.config/quickshell/services/Theme.qml` (`currentTheme`, ~line 10)

**Interfaces:**
- Produces: `Theme.previewName : string` (default `""`). When non-empty, `Theme.currentTheme` follows it; else follows `Config.theme.name`. Setting it hot-swaps colors globally; clearing reverts.

- [ ] **Step 1: Add the override**

Replace:
```qml
    property string currentTheme: Config.theme.name
```
with:
```qml
    // previewName wins when set (live preview from the theme switcher); empty
    // falls back to the committed Config.theme.name.
    property string previewName: ""
    property string currentTheme: root.previewName !== "" ? root.previewName : Config.theme.name
```

- [ ] **Step 2: Deploy + verify starts clean** (rsync + relaunch). Colors unchanged (previewName empty → follows config). No errors.

- [ ] **Step 3: Commit**

```bash
git add .config/quickshell/services/Theme.qml
git commit -m "feat(services): Theme.previewName override for live preview

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 6: `ThemeEntry` component (2-line: name + palette row)

**Files:**
- Create: `.config/quickshell/components/ThemeEntry.qml`

**Interfaces:**
- Produces: `ThemeEntry { name: string; palette: object; selected: bool }` — fixed-width rounded card; line 1 = centered name, line 2 = a row of color swatches drawn from `palette` (its OWN colors, independent of the live `Theme`). `selected` draws an accent border. Uses `Theme.surface`/`Theme.text`/`Theme.accent` and `Config.font.family` for the card chrome (matches `Entry.qml`).

- [ ] **Step 1: Write the component**

```qml
import QtQuick
import QtQuick.Effects

import qs.services

// Theme-switcher card: name (centered) over a palette preview row. The swatches
// use the entry's OWN palette so each card shows its theme regardless of the
// current live preview.
Item {
    id: root

    property string name: "Theme"
    property var palette: ({})
    property bool selected: false

    // Ordered subset shown as swatches.
    readonly property var swatchKeys: ["background", "surface", "accent", "accentHover", "text"]

    implicitWidth: 168
    implicitHeight: 52

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.surface
        border.width: root.selected ? 2 : 0
        border.color: Theme.accent

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#73000000" // black @ 0.45
            blurMax: 16
            shadowBlur: 1.0
            shadowHorizontalOffset: -8
            shadowVerticalOffset: 8
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.name
            color: Theme.text
            font.family: Config.font.family
            font.pixelSize: 13
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.width - 24)
            horizontalAlignment: Text.AlignHCenter
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            Repeater {
                model: root.swatchKeys
                delegate: Rectangle {
                    required property string modelData
                    width: 18
                    height: 12
                    radius: 3
                    color: root.palette[modelData] ?? "transparent"
                    border.width: 1
                    border.color: "#33000000"
                }
            }
        }
    }
}
```

- [ ] **Step 2: Register in components qmldir if that dir uses one**

Check `.config/quickshell/components/qmldir` — if components are listed there, add `ThemeEntry 1.0 ThemeEntry.qml` matching the existing format. If the dir has no qmldir (implicit), skip.

- [ ] **Step 3: Deploy + verify starts clean** (rsync + relaunch). No errors (component not instantiated yet).

- [ ] **Step 4: Commit**

```bash
git add .config/quickshell/components/ThemeEntry.qml .config/quickshell/components/qmldir
git commit -m "feat(components): ThemeEntry — name + palette-preview card

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 7: `ThemeMenu` module (radial, aliases, hover-preview, commit)

**Files:**
- Create: `.config/quickshell/modules/ThemeMenu.qml`

**Interfaces:**
- Consumes: `Themes.list` (Task 4), `Theme.previewName`/`Theme.currentTheme` (Task 5), `ThemeEntry` (Task 6), `Search` component + `Search.rank` (Tasks 1-2), `Config.baseJson`/`Config.theme.name` (existing).
- Produces: IPC target `thememenu` with `toggle()/open()/close()`. Writes `config.json` on commit.

- [ ] **Step 1: Write the module** (clone AppMenu's radial scaffolding; theme-specific bits called out)

```qml
import Quickshell
import Quickshell.Io
import QtQuick

import qs.services
import qs.components
import "scripts/search.js" as Search

// Radial theme switcher: opens prefilled with the current theme's variant alias
// (@dark / @light). Hover/arrow selects and LIVE-PREVIEWS; Enter/click commits
// to config.json; Esc/click-away reverts. IPC: qs ipc call thememenu toggle
PanelWindow {
    id: win

    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    focusable: true
    exclusiveZone: 0

    property var results: win.filterThemes(search.text)
    property int selected: 0

    readonly property int ringR: 240
    readonly property int ringD: 170
    readonly property var slots: [
        Qt.point(0, -win.ringR),
        Qt.point(win.ringD, -win.ringD),
        Qt.point(-win.ringD, -win.ringD),
        Qt.point(win.ringR, 0),
        Qt.point(-win.ringR, 0),
        Qt.point(win.ringD, win.ringD),
        Qt.point(-win.ringD, win.ringD),
        Qt.point(0, win.ringR)
    ]

    function currentVariant(): string {
        for (const t of Themes.list)
            if (t.name === Config.theme.name)
                return t.variant
        return "dark"
    }

    // "@dark"/"@light" [name] | "" -> all | name -> ranked all
    function filterThemes(q: string): var {
        const raw = (q || "").trim()
        const m = raw.match(/^@(dark|light)\b\s*(.*)$/i)
        if (m) {
            const variant = m[1].toLowerCase()
            const rest = m[2].trim()
            const subset = Themes.list.filter(t => t.variant === variant)
            if (rest === "")
                return subset.slice(0, 8)
            return Search.rank(subset, rest, t => t.name)
        }
        if (raw === "")
            return Themes.list.slice(0, 8)
        return Search.rank(Themes.list, raw, t => t.name)
    }

    function preview(): void {
        const t = win.results[win.selected]
        Theme.previewName = t ? t.name : ""
    }
    onSelectedChanged: win.preview()
    onResultsChanged: { win.selected = 0; win.preview() }

    function open(): void {
        search.text = "@" + win.currentVariant() + " "
        win.visible = true
        search.input.forceActiveFocus()
        search.input.cursorPosition = search.text.length
    }
    function close(): void {
        Theme.previewName = ""
        search.text = ""
        win.visible = false
    }
    function toggle(): void { win.visible ? win.close() : win.open() }

    function commit(name: string): void {
        // Merge into the last-good base config and write config.json. Use a
        // detached process with base64 to avoid any shell-quoting issues.
        const obj = JSON.parse(JSON.stringify(Config.baseJson || {}))
        obj.theme = obj.theme || {}
        obj.theme.name = name
        const json = JSON.stringify(obj, null, 2) + "\n"
        const b64 = Qt.btoa(json)
        const path = Quickshell.shellPath("config.json")
        Quickshell.execDetached(["sh", "-c", `printf %s '${b64}' | base64 -d > "${path}"`])
        // Config's FileView hot-reload updates Config.theme.name; drop the
        // preview so Theme follows the committed value.
        Theme.previewName = ""
    }
    function commitSelected(): void {
        const t = win.results[win.selected]
        if (t) { win.commit(t.name); win.close() }
    }

    IpcHandler {
        target: "thememenu"
        function toggle(): void { win.toggle() }
        function open(): void { win.open() }
        function close(): void { win.close() }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        readonly property int deadZone: 110

        function sectorAt(mx: real, my: real): int {
            const dx = mx - win.width / 2
            const dy = my - win.height / 2
            if (Math.hypot(dx, dy) < deadZone)
                return -1
            const ang = Math.atan2(dy, dx)
            let best = -1, bestDiff = Infinity
            for (let i = 0; i < 8; i++) {
                const s = win.slots[i]
                let d = Math.abs(ang - Math.atan2(s.y, s.x))
                if (d > Math.PI) d = 2 * Math.PI - d
                if (d < bestDiff) { bestDiff = d; best = i }
            }
            return win.results[best] != null ? best : -1
        }

        onPositionChanged: e => {
            const idx = sectorAt(e.x, e.y)
            if (idx >= 0) win.selected = idx
        }
        onClicked: e => {
            const idx = sectorAt(e.x, e.y)
            if (idx >= 0) { win.commit(win.results[idx].name); win.close() }
            else win.close()
        }
    }

    Repeater {
        model: 8
        delegate: Rectangle {
            required property int index
            readonly property var t: win.results[index] ?? null
            readonly property point off: win.slots[index]
            height: 2
            width: t ? Math.hypot(off.x, off.y) : 0
            color: Theme.accentMuted
            antialiasing: true
            x: win.width / 2
            y: win.height / 2 - 1
            transformOrigin: Item.Left
            rotation: Math.atan2(off.y, off.x) * 180 / Math.PI
            opacity: t ? 1 : 0
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    Repeater {
        model: 8
        delegate: ThemeEntry {
            id: cell
            required property int index
            readonly property var t: win.results[index] ?? null
            visible: opacity > 0
            name: t ? t.name : ""
            palette: t ? t.palette : ({})
            selected: index === win.selected && t !== null
            x: win.width / 2 - width / 2 + (t ? win.slots[index].x : 0)
            y: win.height / 2 - height / 2 + (t ? win.slots[index].y : 0)
            opacity: t ? 1 : 0
            scale: t ? 1 : 0.5
            Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        }
    }

    Search {
        id: search
        placeholder: "THEME"
        anchors.centerIn: parent
        onNavigate: d => {
            if (win.results.length > 0)
                win.selected = (win.selected + d + win.results.length) % win.results.length
        }
        onAccepted: win.commitSelected()
        onCancelled: win.close()
    }
}
```

- [ ] **Step 2: Confirm `Qt.btoa` handles UTF-8**

The one non-ASCII risk is a theme name with Cyrillic etc.; theme names here are ASCII, and `config.json` content is ASCII. `Qt.btoa` operates on the string's Latin-1/UTF-16 — if a non-ASCII value ever appears, switch the encode to build base64 from a UTF-8 byte array. Not needed for the current theme set; leave a `// ponytail: ASCII config only` note at the `Qt.btoa` line.

- [ ] **Step 3: Wire into shell.qml** (needed to test) — see Task 8, then return here to verify.

- [ ] **Step 4: Commit** (after Task 8 verification passes)

```bash
git add .config/quickshell/modules/ThemeMenu.qml
git commit -m "feat(modules): ThemeMenu — radial theme switcher with live preview

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 8: Wire `ThemeMenu` into the shell + full verification

**Files:**
- Modify: `.config/quickshell/shell.qml` (instantiate `ThemeMenu` per-screen, like `AppMenu`)

**Interfaces:**
- Consumes: `ThemeMenu` (Task 7).

- [ ] **Step 1: Instantiate per-screen**

In `shell.qml`, wherever `AppMenu` is instantiated (per-screen `Variants`/`Repeater` over screens), add a sibling `ThemeMenu { }` with the same screen wiring. Match the exact pattern already used for `AppMenu` in that file (read it first; mirror it).

- [ ] **Step 2: Deploy + verify starts clean** (rsync + relaunch; check `journalctl` for QML errors).

- [ ] **Step 3: USER CHECKPOINT — full visual verification**

Ask the user to `qs ipc call thememenu toggle` and confirm:
1. Opens prefilled with current variant alias (`@dark ` / `@light `); ring lists that variant.
2. Editing to `@light`/`@dark` swaps the listed set; `@dark Nord` filters by name; clearing the box + typing a name searches all themes.
3. Each card shows its OWN palette swatches + centered name.
4. Hover / arrow-select live-previews the whole shell; Esc / click-away reverts to the previous theme.
5. Enter / click commits; the theme sticks after a `systemctl --user restart`-style relaunch (persisted to `config.json`).

**Do not proceed until confirmed.** If commit doesn't persist, inspect `config.json` on the VM (`ssh test@… cat ~/.config/quickshell/config.json`) — verify `theme.name` changed and the file is valid JSON; if the `execDetached` write failed, debug the shell command / base64 path.

- [ ] **Step 4: Commit ThemeMenu (Task 7) + wiring together**

```bash
git add .config/quickshell/modules/ThemeMenu.qml .config/quickshell/shell.qml
git commit -m "feat(modules): wire ThemeMenu into shell per-screen

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

- [ ] **Step 5: Note the config.json diff**

Committing a theme on the VM edits `config.json` in the deployed copy (not the repo). If you want a default theme change in the repo, edit `config.json` intentionally in a separate commit; otherwise leave the repo's `config.json` as-is. (The VM's `config.test.json` host override still wins there for its own keys.)

---

### Task 9: Integrate the branch

**Files:** none (git only)

- [ ] **Step 1: Rebase onto quickshell**

```bash
git checkout theme-switcher
git rebase quickshell
```
Resolve any conflicts (none expected — disjoint files except AppMenu.qml, already on quickshell).

- [ ] **Step 2: Merge to main**

Per user's flow. Confirm with the user whether `quickshell` should also advance (e.g. fast-forward `quickshell` to include the feature) before merging to `main`. Then:
```bash
git checkout main
git merge --no-ff theme-switcher
```
(Leave `index.html`, `style.css`, and the dangling `docs/` deletions untouched throughout.)

- [ ] **Step 3: Final VM deploy from main** (rsync + relaunch) and a last user visual sign-off.

---

## Self-Review

**Spec coverage:**
- Reusable search → Task 1 (§1). ✔
- Themes service (name/variant/palette, auto-discover) → Task 4 (§2). ✔
- Theme live-preview override → Task 5 (§3). ✔
- ThemeMenu radial + prefilled alias + hover preview + commit/cancel + IPC → Tasks 7-8 (§4). ✔
- Alias parsing (`@dark`/`@light` [name], plain name, empty) → Task 7 `filterThemes` (§5). ✔
- Commit → config.json → Task 7 `commit` (§6). ✔
- Themes + variant tagging → Task 3 (§7). ✔
- Wiring (qmldir/Search placeholder/shell.qml) → Tasks 2, 4, 8 (§8). ✔
- 2-line palette entry → Task 6 (§4a). ✔
- AppMenu post-step-1 checkpoint → Task 1 Step 7. ✔

**Placeholder scan:** No TBD/TODO left; the one deliberate ceiling (`Qt.btoa` ASCII-only) is marked with a `ponytail:` note and an upgrade path.

**Type consistency:** `rank(items, query, keyFn)` used identically in Tasks 1, 7. `Themes.list` shape `{name,variant,palette}` consistent across Tasks 4/6/7. `Theme.previewName` set/cleared consistently in Task 7 (`preview`/`close`/`commit`). `ThemeEntry { name; palette; selected }` matches Task 6 definition. IPC target `thememenu` matches the shell/verification steps.
