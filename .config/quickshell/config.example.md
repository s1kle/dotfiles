# Quickshell config reference

`services/Config.qml` loads `config.json` (base, tracked in git) then deep-merges
`config.<hostname>.json` (host override, `/etc/hostname` read at startup) on top.
Objects merge key-by-key recursively; **arrays replace wholesale** — a host file
that sets `sidebar.items` replaces the *entire* list, it does not merge by index.
A key missing from an override just falls through to the base/default value.
Both files hot-reload (`FileView.watchChanges`); a broken JSON file keeps that
file's last-good parse instead of reverting to defaults.

Host files are optional and per-machine:

- `config.test.json` — VM (hostname `test`)
- `config.laptop.json` — laptop (hostname `laptop`), **gitignored**, holds
  every laptop-only sidebar item (wifi/bluetooth/battery/tray/vpn/nightlight/
  recording/gpu) on top of the base list below

This file documents every key `Config.qml`'s `defaults` object defines, with the
shipped default value. Copy any subset into `config.json` or a host file to
override — you don't need to repeat keys you're not changing.

```jsonc
{
  // Active theme, by name — must match a file in themes/<name>.json.
  "theme": { "name": "Nord" },

  // Shared corner-radius/margin (RailTile, NotificationPanel, ThemeMenu...).
  "layout": {
    "radius": 12,
    "margin": 6
  },

  // Font family used across every widget's Label/font.family binding
  // (sizes are hardcoded per-widget via font.pixelSize, not configurable).
  "font": { "family": "Annotation Mono" },

  // City for the Open-Meteo lookup (services/Weather.qml geocodes this string).
  "weather": { "city": "Primorsky Krai, Nakhodka", "refreshMinutes": 15 },

  // components/Progress.qml ring size/stroke width (px), used by RailGauge.
  "progress": { "size": 66, "width": 8 },

  // TopBar's expanded rack: which widgets show, in order, when the island
  // opens. "music" auto-hides itself when there's no active player.
  "topbar": {
    "collapseDelay": 0,
    "widgets": ["clock", "weather", "music"]
  },

  // Right-edge hover sidebar (modules/Sidebar.qml).
  "sidebar": {
    "enabled": true,
    "width": 210,        // rail width in px (window adds +40 for shadow room)
    "trigger": 100,       // px-wide invisible hover zone at the screen edge that opens the rail
    "tileSize": 42,       // px size of one small tile (RailTile.size)
    "gap": 6,             // px spacing between tiles, rows, and columns
    "columns": 4,         // grid column count the row-packer fills
    "scrollStep": 0.05,   // value change per accumulated scroll step (0..1 range)
    "scrollThreshold": 120,  // wheel/touchpad delta accumulated before one step fires (~1 mouse notch)
    "scrollInvert": false,   // flip scroll direction
    "collapseDelay": 250,    // ms idle before the rail auto-collapses
    // Ordered tile layout. Each entry is either:
    //   { "id": "<tile-id>", "size": "small" | "wide" | "big" }
    //   { "type": "divider" }   — thin separator row
    //   { "type": "spacer" }    — Layout.fillHeight, pushes the rest to the bottom
    // Known ids (see modules/Sidebar.qml tileFor()): clock, workspaces,
    // weather, music, volume, brightness, mic, notifications, network,
    // bluetooth, cpu, mem, disk, download, upload, battery, power, appmenu,
    // screenshot, clipboard, updates, vpn, nightlight, recording, temp,
    // uptime, gpu, hyprlayout (dwindle/master toggle, click to switch),
    // calendar.
    // Hosts (e.g. config.laptop.json) replace this whole array — see
    // Config.qml's deepMerge note: arrays are never index-merged.
    "items": [
      { "id": "clock",      "size": "wide" },
      { "id": "calendar",   "size": "wide" },
      { "id": "workspaces", "size": "wide" },
      { "id": "weather",    "size": "wide" },
      { "id": "music",      "size": "wide" },
      { "type": "divider" },
      { "id": "hyprlayout", "size": "small" },
      { "type": "divider" },
      { "id": "volume", "size": "small" }, { "id": "brightness", "size": "small" },
      { "id": "mic",    "size": "small" }, { "id": "notifications", "size": "small" },
      { "id": "appmenu", "size": "small" },
      { "id": "screenshot", "size": "small" },
      { "id": "clipboard", "size": "small" },
      { "type": "divider" },
      { "id": "cpu",  "size": "small" }, { "id": "mem", "size": "small" },
      { "id": "disk", "size": "small" }, { "id": "download", "size": "small" },
      { "id": "upload", "size": "small" },
      { "id": "temp", "size": "small" }, { "id": "uptime", "size": "wide" },
      { "id": "updates", "size": "small" },
      { "type": "spacer" },
      { "id": "power", "size": "wide" }
    ]
  }
}
```

## Laptop (`config.laptop.json`) additions

The laptop host has hardware the VM doesn't (wifi, bluetooth, battery), so its
`sidebar.items` override adds those tiles and drops `notifications` from the
main cluster in favor of a dedicated one — see the file itself (gitignored,
laptop-local) for the live list. Laptop-only ids not in `Config.defaults`:
`tray`, `vpn` (NetworkManager VPN toggle via `nmcli`), `nightlight`
(hyprsunset toggle), `recording` (wf-recorder start/stop via optimistic state + `pkill -x`,
pulsing dot while active), `gpu` (usage ring; no GPU on the VM host).
`temp`/`uptime` are universal (in `Config.defaults`), not laptop-only.
