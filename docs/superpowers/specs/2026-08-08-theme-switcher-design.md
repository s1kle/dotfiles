# Theme switcher (radial) — design

Date: 2026-08-08

A radial theme switcher for the Quickshell shell, modelled on the existing
`AppMenu`. Browse installed themes, **live-preview on hover**, **commit on
Enter/click**. Search by direct name or by `@dark` / `@light` aliases. Along the
way, extract the app-menu's search/ranking logic into a reusable helper.

## Goals

- Reuse the app-menu search/ranking logic (don't duplicate it).
- Radial surface (same 8-slot compass layout, spokes, keyboard + mouse-sector
  selection) as `AppMenu`.
- Two-line entries: **name (centered)** + **palette preview** (row of swatches).
- Search accepts:
  - direct name — `NordTheme`
  - variant alias — `@dark` / `@light` (lists all of that variant)
  - alias + name — `@dark Nord`
- On open, prefill the search with the **current theme's variant alias**
  (current theme dark → box starts `@dark `, ring lists all dark themes). User
  edits from there (switch to `@light`, append a name, or clear and type a name).
- Hover / arrow-select → **live preview** (recolors the whole shell instantly).
- Enter / mouse-click → **commit** (persist). Esc / click-away → revert + close.
- Add 6 popular themes (3 dark, 3 light) and tag existing themes by variant.

## Non-goals

- More than 8 visible results. The radial ring caps at 8; after an `@variant`
  filter that's fine now (max 5 dark / 3 light). If the theme set grows past 8
  per variant later, results silently truncate — accepted for now.
- Per-host theme commit. Commit writes the shared base `config.json` (user's
  explicit choice); this shows as a git diff on `config.json`.

## Architecture

Follows the existing layer split (`services` → `components` → `widgets` →
`modules`).

### 1. Reusable search — `modules/scripts/search.js`

Extract the ranking currently inline in `AppMenu.filterApps` into a shared JS
library imported by both menus:

```js
// rank(items, query, keyFn) -> array of items, ranked, sliced to 8
// rank tiers: name-prefix (0) > word-start (1) > substring (2);
// alphabetical tie-break within a tier. filter() copies, so the caller's
// source list is never reordered.
```

- `AppMenu` → `Search.rank(Apps.list, q, a => a.name)`.
- `ThemeMenu` → alias-preprocess `Themes.list`, then `Search.rank(subset, name, t => t.name)`.

Placed in `modules/scripts/` (keeps loose scripts out of the module dir itself);
imported from a module as `import "scripts/search.js" as Search`.

**Checkpoint:** after this extraction + `AppMenu` refactor, deploy to the VM and
have the user verify `AppMenu` still filters/launches correctly before building
the theme switcher.

### 2. `Themes` service — `services/Themes.qml` (singleton, add to `qmldir`)

Auto-discovers `themes/*.json` and exposes:

```
readonly property var list  // [{ name, variant, palette }, ...] sorted by name
```

- Enumerate files with `Qt.labs.folderlistmodel` `FolderListModel`
  (`folder: themes/`, `nameFilters: ["*.json"]`).
- Load each file (an `Instantiator` of `FileView` loaders, or equivalent) and
  build `{ name: <basename>, variant: json.variant, palette: json }`.
- No manifest to maintain — dropping in a new theme file just appears.

`palette` is the parsed color object (background/surface/accent/text/…), used for
the swatch row in the entry.

### 3. Live preview — `Theme` service override

`services/Theme.qml`:

```
property string previewName: ""
property string currentTheme: previewName !== "" ? previewName : Config.theme.name
```

(`currentTheme` becomes a computed binding.) The `FileView` path already keys off
`currentTheme`, so setting `previewName` hot-swaps colors globally. Clearing it
reverts to the committed `Config.theme.name`.

### 4. `ThemeMenu` module — `modules/ThemeMenu.qml`

Cloned from `AppMenu` (PanelWindow, transparent fullscreen, focusable, 8 slots,
spokes `Repeater`, entries `Repeater`, center `Search`, mouse-sector `MouseArea`,
`IpcHandler`). Differences:

- **Filter:** `filterThemes(query)` — see §5.
- **Entry:** a new 2-line theme entry (see §4a) instead of the app `Entry` pill.
- **Open:** `open()` sets `search.text = "@" + currentVariant + " "`, focuses the
  input, cursor at end. `currentVariant` = variant of `Config.theme.name` from
  `Themes.list`.
- **Preview:** selecting an entry (hover, mouse-sector, or arrow) sets
  `Theme.previewName = results[selected].name`.
- **Commit:** `commitSelected()` → write `config.json` (§6), `Theme.previewName = ""`,
  close.
- **Cancel:** `close()` → `Theme.previewName = ""`, hide. (Esc, click-away.)
- **IPC:** `target: "thememenu"`, `toggle()/open()/close()`.

#### 4a. Theme entry (2-line)

A small component (either a new `components/ThemeEntry.qml` or inline in
ThemeMenu — decide during implementation, prefer a component for isolation):

- Fixed-width rounded card (match Entry's surface + shadow tokens).
- Line 1: theme name, centered, `Theme.text`, `Config.font.family`.
- Line 2: palette preview — a `Row` of small color swatches drawn from the
  entry's `palette` (e.g. background, surface, accent, accentHover, text — a
  fixed ordered subset), each a rounded `Rectangle`.
- `selected` draws an accent border (same convention as `Entry`).

Colors come **from the entry's own `palette`** (not the live `Theme` tokens), so
each card shows its own theme's colors regardless of the current live preview.

### 5. Alias parsing — `filterThemes(query)`

```
q = query.trim()
if q starts with "@dark" or "@light":
    variant = that word without "@"
    rest    = remainder of the string, trimmed
    subset  = Themes.list where t.variant === variant
    return rest === "" ? subset (sorted) : Search.rank(subset, rest, t => t.name)
else if q === "":
    return Themes.list (all, sorted)   // (open() always prefills an alias, so
                                       //  this is the "user cleared it" case)
else:
    return Search.rank(Themes.list, q, t => t.name)
```

`@` with no valid variant word → treat as a plain name search (no crash).

### 6. Commit → `config.json`

```
obj = deep copy of Config.baseJson (fallback: {})
obj.theme = obj.theme || {}
obj.theme.name = chosenName
write JSON.stringify(obj, null, 2) to config.json
```

Write via a `FileView` bound to `config.json` with write support (confirm the
Quickshell FileView write API during implementation — `setText`/`JsonAdapter`;
if unavailable, fall back to `Quickshell.execDetached` writing the file). Config's
existing hot-reload re-reads and updates `Config.theme.name`; then clearing
`previewName` makes `Theme` follow the committed value. Preserves all other
config keys (comments are lost — JSON has none).

### 7. Themes + variant tagging

Add `"variant"` to every theme JSON:

- Existing: `NordTheme` → `dark`, `CatppuccinMocha` → `dark`.
- New dark: `GruvboxDark`, `TokyoNight`, `Dracula`.
- New light: `CatppuccinLatte`, `GruvboxLight`, `RosePineDawn`.

Each new file uses the existing 9-key schema (background, surface, primary,
secondary, accent, accentHover, accentMuted, text, textDim) **plus** `variant`.
`Theme.loadColors` ignores unknown keys (only assigns keys that exist on the
singleton), so `variant` in the file is harmless there.

### 8. Wiring

- `services/qmldir`: register `Themes`.
- `components/Search.qml`: add `property alias placeholder` (currently hardcoded
  `"APP"`); AppMenu passes `"APP"`, ThemeMenu passes `"THEME"`.
- `shell.qml`: instantiate `ThemeMenu` per-screen alongside `AppMenu`.
- Toggle: `qs ipc call thememenu toggle`.

## Testing / verification

Run only on a Hyprland host (VM `test@192.168.31.218`) per repo workflow.

1. After §1: verify `AppMenu` unchanged (filter + launch) — **explicit user
   checkpoint**.
2. After the switcher: user verifies visually —
   - opens prefilled with current variant alias, ring lists that variant;
   - `@light` / `@dark` swap the listed set; `@dark Nord` filters by name;
   - clearing the box + typing a name searches all;
   - hover live-previews the whole shell; Esc/click-away reverts;
   - Enter/click commits, survives a restart (theme persists via `config.json`);
   - palette swatches show each theme's own colors.

## Open implementation details (decide while building)

- Quickshell `FileView` write API for §6 (vs `execDetached` fallback).
- `ThemeEntry` as its own component vs inline (prefer component).
- Exact swatch subset/order for the palette row.
