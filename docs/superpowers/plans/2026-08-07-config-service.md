# Config Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `Config` singleton service holding all non-color shell configuration (layout, shadows, fonts, theme name, widget toggles) with per-host JSON overrides and hot-reload.

**Architecture:** `services/Config.qml` (`pragma Singleton`, module `qs.services`) holds QML-side defaults as section objects (`theme`, `layout`, `shadow`, `font`, `widgets`). Two `FileView`s watch `config.json` and `config.<hostname>.json` (`/etc/hostname` read via a third FileView). On any load/change, both file contents are deep-merged over the defaults (host wins) and section properties are reassigned, triggering widget bindings. `Theme.qml` switches to reading `Config.theme.name` for its JSON path (one-directional dependency).

**Tech Stack:** QML (quickshell 0.3.0), `Quickshell.Io.FileView` (same pattern as existing Theme.qml), JSON files.

## Global Constraints

- Quickshell 0.3.0 only; no C++ plugin, no new dependencies.
- QML JS: no object spread (`{...x}`) — use `Object.assign({}, x, ...)` (see Bluetooth.qml fix).
- JSON schema and property names are fixed by the spec (`docs/superpowers/specs/2026-08-07-config-service-design.md`): `theme.name`, `layout.{barHeight,barWidth,radius,padding,margin,gap}`, `shadow.{blur,offsetY,opacity}`, `font.{family,sizes.{bar,clock,title}}`, `widgets.{Music,Weather,Workspaces,Settings}`.
- Unknown JSON keys are ignored; missing widget keys default to `true`; invalid JSON keeps last good state and warns once.
- Test host: VM `test@192.168.31.218` (hostname `test`); laptop `senshu_@192.168.31.26` (hostname `player`).

---

### Task 1: Config.qml service

**Files:**
- Create: `quickshell/services/Config.qml`
- Modify: `quickshell/services/qmldir` (add `singleton Config Config.qml`)

**Interfaces:**
- Consumes: nothing (standalone; defaults are internal)
- Produces: singleton `Config` with section properties `theme`, `layout`, `shadow`, `font`, `widgets` (var objects with the exact keys from Global Constraints), plus `readonly property string hostname`, `readonly property bool valid` (true once any JSON parsed successfully)

- [ ] **Step 1: Write `quickshell/services/Config.qml`**

```qml
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string hostname: ""
    property bool valid: false

    // QML-side defaults; JSON files override these. Section objects are
    // replaced wholesale on reload so widget bindings re-evaluate.
    property var defaults: {
        theme: { name: "NordTheme" },
        layout: { barHeight: 34, barWidth: 700, radius: 12, padding: 8, margin: 6, gap: 4 },
        shadow: { blur: 16, offsetY: 2, opacity: 0.35 },
        font: { family: "Inter", sizes: { bar: 12, clock: 14, title: 11 } },
        widgets: { Music: true, Weather: true, Workspaces: true, Settings: true, Battery: true, Bluetooth: true },
    }

    property var theme: defaults.theme
    property var layout: defaults.layout
    property var shadow: defaults.shadow
    property var font: defaults.font
    property var widgets: defaults.widgets

    property string baseText: ""
    property string hostText: ""
    property bool warnedInvalid: false

    function parseJson(text: string): var {
        try {
            return JSON.parse(text)
        } catch (e) {
            if (!root.warnedInvalid) {
                console.warn(`Config: invalid JSON, keeping last good state: ${e?.message ?? e}`)
                root.warnedInvalid = true
            }
            return null
        }
    }

    // Merge driven by base keys: override keys absent from base are ignored,
    // objects recurse, scalars/arrays are replaced wholesale.
    function deepMerge(base: var, override: var): var {
        if (override === undefined || override === null) return base
        if (typeof base !== "object" || typeof override !== "object") return override
        const out = {}
        for (const key of Object.keys(base)) {
            out[key] = root.deepMerge(base[key], override[key])
        }
        return out
    }

    function reapply(): void {
        const base = root.parseJson(root.baseText)
        const host = root.parseJson(root.hostText)
        if (root.baseText === "" && root.hostText === "") return
        if (base === null && host === null) return // keep last good state
        let merged = root.defaults
        if (base !== null) merged = root.deepMerge(merged, base)
        if (host !== null) merged = root.deepMerge(merged, host)
        root.theme = merged.theme
        root.layout = merged.layout
        root.shadow = merged.shadow
        root.font = merged.font
        root.widgets = merged.widgets
        root.valid = true
        root.warnedInvalid = false
    }

    FileView {
        id: baseFile
        path: Quickshell.shellPath("config.json")
        watchChanges: true
        onLoaded: { root.baseText = text(); root.reapply() }
        onFileChanged: { root.baseText = text(); root.reapply() }
        onLoadFailed: err => console.warn(`Config: config.json not loaded: ${FileViewError.toString(err)}`)
    }

    FileView {
        id: hostFile
        path: root.hostname !== "" ? Quickshell.shellPath(`config.${root.hostname}.json`) : ""
        watchChanges: true
        onLoaded: { root.hostText = text(); root.reapply() }
        onFileChanged: { root.hostText = text(); root.reapply() }
        onLoadFailed: () => {} // host file is optional
    }

    FileView {
        id: hostnameFile
        path: "/etc/hostname"
        watchChanges: false
        onLoaded: {
            root.hostname = text().trim()
            hostFile.path = Quickshell.shellPath(`config.${root.hostname}.json`)
        }
        onLoadFailed: () => {} // no hostname -> base config only
    }
}
```

- [ ] **Step 2: Add to `quickshell/services/qmldir`**

```
singleton Config Config.qml
```

- [ ] **Step 3: Commit**

```bash
git add quickshell/services/Config.qml quickshell/services/qmldir
git commit -m "feat: add Config service with JSON defaults and host overrides"
```

---

### Task 2: Config files, smoke-test logging, Theme switch

**Files:**
- Create: `quickshell/config.json`
- Create: `quickshell/config.test.json` (VM fixture)
- Modify: `quickshell/services/Theme.qml` (currentTheme → Config.theme.name)
- Modify: `quickshell/shell-test.qml` (log Config values)

**Interfaces:**
- Consumes: `Config` singleton from Task 1 (`Config.theme.name`, `Config.layout.*`, `Config.font.*`, `Config.widgets.*`, `Config.hostname`)
- Produces: verifiable smoke-test output on the VM

- [ ] **Step 1: Create `quickshell/config.json`** (base values; widgets.Battery/Bluetooth intentionally absent to verify the "missing = true" default)

```json
{
  "theme": { "name": "NordTheme" },
  "layout": { "barHeight": 34, "barWidth": 700, "radius": 12, "padding": 8, "margin": 6, "gap": 4 },
  "shadow": { "blur": 16, "offsetY": 2, "opacity": 0.35 },
  "font": { "family": "Inter", "sizes": { "bar": 12, "clock": 14, "title": 11 } },
  "widgets": { "Music": true, "Weather": true, "Workspaces": true, "Settings": true }
}
```

- [ ] **Step 2: Create `quickshell/config.test.json`** (VM override: distinct values to prove merging — radius/barWidth changed, widgets overridden, font.sizes.clock changed; Battery enabled via override, Bluetooth proves default-true)

```json
{
  "layout": { "barWidth": 640, "radius": 16 },
  "font": { "sizes": { "clock": 16 } },
  "widgets": { "Music": false, "Battery": true }
}
```

- [ ] **Step 3: Modify `quickshell/services/Theme.qml`**

Replace the `currentTheme` property and the FileView `path`:

```qml
    property string currentTheme: Config.theme.name
```

and

```qml
    FileView {
        id: themeFile
        path: Quickshell.shellPath(`themes/${Config.theme.name}.json`)
```

(keep `watchChanges: true` and the `onLoaded`/`onFileChanged`/`onLoadFailed` handlers as-is)

- [ ] **Step 4: Add Config logging to `quickshell/shell-test.qml`**

Inside the existing `Timer.onTriggered` block, after the Bluetooth lines:

```qml
            console.log("SMOKE Config: host", Config.hostname, "valid", Config.valid,
                        "theme", Config.theme.name,
                        "layout", Config.layout.barHeight + "x" + Config.layout.barWidth,
                        "radius", Config.layout.radius, "padding", Config.layout.padding,
                        "shadow", Config.shadow.blur + "/" + Config.shadow.opacity,
                        "font", Config.font.family, Config.font.sizes.bar + "/" + Config.font.sizes.clock + "/" + Config.font.sizes.title,
                        "widgets", JSON.stringify(Config.widgets))
```

- [ ] **Step 5: Commit**

```bash
git add quickshell/config.json quickshell/config.test.json quickshell/services/Theme.qml quickshell/shell-test.qml
git commit -m "feat: add config files, wire Theme to Config, log Config in smoke test"
```

---

### Task 3: VM verification

**Files:**
- Modify: `quickshell/config.test.json` (hot-reload + invalid-JSON tests)

**Interfaces:**
- Consumes: all of Tasks 1-2
- Produces: verified behavior on VM

- [ ] **Step 1: Sync and run smoke test on VM**

```bash
rsync -a --delete /home/senshu_/dotfiles/quickshell/ test@192.168.31.218:/home/test/.config/quickshell/
ssh test@192.168.31.218 'SIG=$(ls /run/user/1000/hypr/ | head -1); export HYPRLAND_INSTANCE_SIGNATURE="$SIG" WAYLAND_DISPLAY=wayland-1 XDG_RUNTIME_DIR=/run/user/1000; timeout 50 quickshell -p /home/test/.config/quickshell/shell-test.qml 2>&1 | grep "SMOKE Config" | head -3'
```

Expected (merged values, tick 2+): `host test valid true theme NordTheme layout 34x640 radius 16 padding 8 shadow 16/0.35 font Inter 12/16/11 widgets {"Music":false,"Weather":true,"Workspaces":true,"Settings":true,"Battery":true,"Bluetooth":true}`

- [ ] **Step 2: Hot-reload test**

While a smoke run is looping (it repeats 3x at 8s), edit `config.test.json` on the VM (e.g. `"radius": 20`) between ticks. Expected: subsequent tick logs `radius 20` without restart.

- [ ] **Step 3: Invalid-JSON fallback test**

Overwrite `config.test.json` on the VM with `{ "layout": ` (broken). Expected: warning once, previous values retained (radius stays 20). Restore the file afterwards.

- [ ] **Step 4: Base-only sanity on laptop**

```bash
ssh senshu_@192.168.31.26 'rm -f /home/senshu_/.config/quickshell/config.player.json'
```

Then run the same smoke test on the laptop. Expected: `host player valid true` with base values (radius 12, barWidth 700), Theme still loads NordTheme colors.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "test: verify Config service on VM and laptop"
```

(only if verification produced changes; otherwise skip commit)
