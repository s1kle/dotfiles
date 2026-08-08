# TopBar (dynamic island) — design

Date: 2026-08-08

A top-center "dynamic island" for the Quickshell shell. Collapsed by default
(clock + focused app); on hover it springs open into a widget rack
(clock · weather · music) and collapses again after a configurable idle delay.
Backed by new `Weather` and `FocusedWindow` services; music/clock reuse existing
`Mpris`/`Time`.

Design source: `index.2026-08-08.html.bak` / `style.2026-08-08.css.bak` (the
`.topbar` block). Icons are SVG/vector, not glyph symbols.

## Goals

- Collapsed pill: clock (left) + focused-app icon+name (right).
- Hover → spring-expand to a rack: **Clock** (time + date) · **Weather**
  (morning/now/evening) · **Music** (cover, track/artist, prev/play-pause/next,
  seekable progress). Cross-fade collapsed↔expanded.
- Collapse back after the pointer leaves for `Config.topbar.collapseDelay`
  (default 1500 ms); re-entering cancels the pending collapse.
- Live data: `Time`, `Mpris`, new `Weather`, new `FocusedWindow`.
- Media controls as **QtQuick.Shapes** (theme-colorable); weather as **bundled
  SVGs** tinted to the theme.
- Primary screen only. Focused-app reflects the global active window (any monitor).

## Non-goals

- No changes to the existing `Bar` module (kept as-is; it's a test surface).
- No multi-provider weather; Open-Meteo only. No API keys.
- No per-monitor TopBar instances.

## Architecture

Layer split: `services` (data) → `components`/`widgets` (dumb UI) →
`modules` (smart panel). `qs.<dir>` imports.

### Services (data)

#### `services/Weather.qml` (singleton; add to `services/qmldir`)

Open-Meteo, no key. Two-step: geocode the city, then fetch today's hourly
forecast; pick morning/now/evening samples.

Exposes:
```
readonly property bool ready       // first successful fetch done
readonly property string error     // "" when ok, else a short message
readonly property var morning      // ({ temp: int, code: int }) or null
readonly property var now          // ({ temp: int, code: int }) or null
readonly property var evening      // ({ temp: int, code: int }) or null
```

Behavior:
- Geocode `Config.weather.city` via
  `https://geocoding-api.open-meteo.com/v1/search?name=<city>&count=1`.
  Send the last comma-separated segment of the city string (so
  `"Приморский край, Находка"` → `"Находка"`), URL-encoded. Cache the resulting
  `{lat, lon}` in a property; only re-geocode when `Config.weather.city` changes.
- Forecast via
  `https://api.open-meteo.com/v1/forecast?latitude=<lat>&longitude=<lon>&hourly=temperature_2m,weathercode&timezone=auto&forecast_days=1`.
- Sample hours: morning = 09:00, evening = 21:00, now = current hour (clamped to
  the returned range). `temp` = rounded `temperature_2m`; `code` = WMO
  `weathercode`.
- Fetch with QML `XMLHttpRequest` (GET). Refresh on a `Timer`
  (`Config.weather.refreshMinutes`, default 15) and once on startup.
- On any failure: set `error`, leave last-good values in place (don't blank a
  working widget); `ready` stays false until the first success.

WMO code → icon key mapping (used by the widget to choose an SVG), as a
function `iconFor(code): string`:
| WMO codes | key |
|-----------|-----|
| 0 | `clear` |
| 1,2 | `partly` |
| 3 | `cloudy` |
| 45,48 | `fog` |
| 51,53,55,56,57 | `drizzle` |
| 61,63,65,66,67,80,81,82 | `rain` |
| 71,73,75,77,85,86 | `snow` |
| 95,96,99 | `thunder` |

#### `services/FocusedWindow.qml` (singleton; add to `services/qmldir`)

Wraps the global active toplevel (`Quickshell.Wayland` `ToplevelManager`).

Exposes:
```
readonly property string appId   // active toplevel appId ("" if none)
readonly property string title   // active toplevel title
readonly property string name    // desktop-entry name, else appId, else "" 
readonly property string icon    // freedesktop icon name from the desktop entry ("" if none)
```
- Resolve `appId` through `DesktopEntries` (best-effort, case-insensitive) to a
  `{ name, icon }`. Icon consumed via `Quickshell.iconPath(icon, true)` in the
  widget (missing → hidden, same as `Entry`).
- Updates reactively as `ToplevelManager.activeToplevel` changes.

#### `services/Time.qml` (extend)

Add the display formats the design uses (keep existing `time`/`date`):
```
readonly property string clockTime   // "hh:mm"
readonly property string longDate    // "ddd, MMM d"  e.g. "Fri, Aug 8"
```

### Assets

`.config/quickshell/assets/weather/*.svg` — monochrome (single-color) SVGs, one
per icon key: `clear, partly, cloudy, fog, drizzle, rain, snow, thunder`.
Rendered via `Image` and tinted to a `Theme.*` token with `MultiEffect`
(`colorization: 1`), so they follow the active theme. Loaded by
`Quickshell.shellPath("assets/weather/<key>.svg")`.

### Components (generic primitives)

- `components/MediaButton.qml` — a clickable **QtQuick.Shapes** icon button.
  Props: `kind: "prev"|"next"|"play"|"pause"`, `size`, `color`, `enabled`;
  signal `clicked()`. Vector paths drawn with `Shape`/`ShapePath`, `fillColor:
  color` so it recolors with the theme. Dims when `!enabled`.
- `components/ProgressBar.qml` — thin horizontal bar, `value` 0..1, optional
  `seekable`; emits `seek(real fraction)` on click/drag. (The existing
  `Progress` is a ring; this is the linear analogue. Reuse `Slider`'s drag math
  if it fits; otherwise a minimal MouseArea + fill Rectangle.)

### Widgets (dumb, placeholder-driven)

- `widgets/ClockWidget.qml` — `time` + `date` strings; big time over dim date.
- `widgets/WeatherWidget.qml` — three slots `{temp, code}` (morning/now/evening);
  dim sides, bright center; each slot = tinted weather SVG + temp. Uses
  `Weather.iconFor(code)` to pick the asset. Placeholder-driven (module binds it).
- `widgets/MusicWidget.qml` — cover image (or gradient fallback), track/artist,
  `MediaButton` ×3, `ProgressBar`. Placeholders: `coverUrl, track, artist,
  playing, canPrev, canNext, canSeek, position, length`; signals `prev/next/
  playPause/seek(frac)`.
- `widgets/FocusedApp.qml` — icon (hidden if missing) + name; placeholders
  `icon, name`.

### Module

`modules/TopBar.qml` — top-center `PanelWindow` on the **primary screen**.

- Two stacked layers, both centered: `pillCollapsed` (ClockWidget-mini + FocusedApp)
  and `pillExpanded` (ClockWidget | WeatherWidget | MusicWidget separated by
  dividers). A background `Rectangle` (radius, `Theme.surface`, shadow) animates
  `width`/`height` between collapsed (168×34) and expanded (~525×76) sizes with
  the design's spring curve; the two layers cross-fade on `expanded`.
- **Expand/collapse:** a `HoverHandler` (or MouseArea) over the pill sets
  `expanded = true` on enter; on exit, start a `Timer`
  (`Config.topbar.collapseDelay`) that sets `expanded = false`; re-enter stops it.
- **Input mask:** `mask: Region { … }` tracks the pill's *current* animated rect
  so the transparent window area around the collapsed pill doesn't intercept
  clicks meant for windows underneath.
- **Wiring:** ClockWidget ← `Time`; WeatherWidget ← `Weather`; FocusedApp ←
  `FocusedWindow`; MusicWidget ← `Mpris` (`activePlayer`): `track`/`artist` from
  `Mpris.activeTrack`, `playing` from `Mpris.isPlaying`, controls →
  `Mpris.togglePlaying/next/previous` (guarded by `canGoNext/Previous`), cover
  from the track art url. Position/seek from `Mpris.activePlayer.position/length`
  (poll with a 1 s `Timer` while playing); `seek(frac)` → set
  `activePlayer.position = frac*length` when `activePlayer.canSeek`.
- Instantiated once in `shell.qml`, bound to the primary screen; `Bar` untouched.

### Config additions (`services/Config.qml` defaults + `config.json`)

```
topbar: { collapseDelay: 1500 }        // ms before collapse after pointer leaves
weather: { city: "…", refreshMinutes: 15 }   // extend existing weather{city}
```
`Config` merges these like the other sections. `config.json` keeps
`weather.city = "Приморский край, Находка"`.

## Data flow

`Weather`/`Time`/`Mpris`/`FocusedWindow` (services) → `TopBar` binds them into
the dumb widgets → widgets render. Control/seek callbacks go back through
`Mpris`. Weather/FocusedWindow are pure data; the widgets never fetch.

## Color tokens

`.bak` CSS colors are throwaway. Intended mapping (each **confirmed with the
user when the widget is built**, per repo convention):
| CSS | token |
|-----|-------|
| pill bg `#1e1e2e` | `Theme.surface` |
| text `#cdd6f4` | `Theme.text` |
| dim `#6c7086` | `Theme.textDim` |
| divider/track `#313244` | `Theme.primary` |
| accent / progress fill `#cba6f7` | `Theme.accent` |
| cover gradient `#cba6f7`→`#89b4fa` | `Theme.accent` → (TBD: `accentHover`/`secondary`) |

## Testing / verification

Runs only on the Hyprland VM (`test@192.168.31.218`) per repo workflow.

- **Node-testable pure logic** (no QML/Wayland needed) — extract into plain JS so
  it can be unit-tested like `search.js`:
  - `Weather.iconFor(code)` WMO→key mapping.
  - Forecast-sampling: given Open-Meteo hourly arrays + a "now" hour, pick the
    morning/now/evening `{temp, code}` triples (indexing, rounding, clamping).
  Put these in `modules/scripts/` or `services/scripts/` with a `.test.mjs`.
- **VM visual sign-off** (user checkpoint) — collapsed pill (clock + focused app,
  incl. focusing a window on another monitor); hover spring-expand; 1.5 s
  auto-collapse and re-enter cancel; weather shows morning/now/evening with
  correct tinted icons; music shows track/art/controls, play/pause/next/prev
  work, progress advances and is seekable; theme switch recolors everything;
  input mask lets clicks through around the collapsed pill.

## Open implementation details (decide while building)

- Exact expanded width/heights and divider styling (from the `.bak` CSS values).
- `ProgressBar`: reuse `Slider` internals vs a minimal bespoke bar.
- Cover-art fallback (gradient) when no art url.
- Whether the geocode cache persists across restarts (start in-memory; add a
  cache file only if the geocoding endpoint rate-limits — `ponytail:` defer).
- Second color for the cover gradient.
