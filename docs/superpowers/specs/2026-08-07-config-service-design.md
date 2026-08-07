# Config Service Design

Date: 2026-08-07
Status: Approved

## Goal

A `qs.services` singleton (`Config`) that owns all non-color shell configuration:
layout constants (paddings, margins, gaps, radius, sizes), shadows, fonts, the
active theme name, and per-widget enable flags — with per-host overrides and
hot-reload. Colors stay in the existing `Theme` service.

## Storage

- `config.json` in the config folder — base values.
- `config.<hostname>.json` — optional per-host overrides, deep-merged on top.
  Hostname read from `/etc/hostname` via `FileView`.
- Both files loaded with `FileView` + `watchChanges` (same pattern as
  `Theme.qml`) → hot reload on save.

## JSON schema (base file)

```jsonc
{
  "theme": { "name": "NordTheme" },
  "layout": { "barHeight": 34, "barWidth": 700, "radius": 12,
              "padding": 8, "margin": 6, "gap": 4 },
  "shadow": { "blur": 16, "offsetY": 2, "opacity": 0.35 },
  "font": { "family": "Inter", "sizes": { "bar": 12, "clock": 14, "title": 11 } },
  "widgets": { "Music": true, "Weather": true, "Workspaces": true, "Settings": true }
}
```

Host file example (`config.player.json`): `{ "widgets": { "Battery": true, "Bluetooth": true } }`

## Service API

`services/Config.qml` — `pragma Singleton`, module `qs.services`:

- Nested read-only properties mirroring the schema:
  `Config.theme.name`, `Config.layout.padding`, `Config.font.family`,
  `Config.font.sizes.bar`, `Config.widgets.Music`, `Config.shadow.blur`, ...
- One property per JSON leaf, typed number/string/bool by content.
- Unknown JSON keys ignored; missing widgets default to `true`.
- Invalid/unparseable JSON → keep last good state, `console.warn` (like Theme).
- Deep-merge: host values win over base, recursively.

## Dependencies

- `Theme.qml` changes: `currentTheme` is replaced by reading
  `Config.theme.name` for its `FileView` path. One-directional dependency
  (Theme → Config), no cycle.

## Testing

- VM (preferred): `config.json` + a `config.<vm-hostname>.json` override;
  verify merged values, hot-reload on file edit, invalid JSON fallback.
- Laptop: verify `config.player.json` override applies; no host file → base only.

## Out of scope

- Colors (Theme service owns them).
- Editing config from UI; behavior flags (clock format etc.) — add later if needed.
