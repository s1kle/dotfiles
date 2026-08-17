local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

hl.layer_rule({
    name = "quickshell-glass",
    match = { namespace = "quickshell-bar" },
    blur = true,
    ignore_alpha = 0.1,
})

hl.window_rule({
    -- let kitty own its translucency via background_opacity (crisp text over
    -- the compositor blur) instead of the global active/inactive_opacity dim.
    name    = "kitty-opacity",
    match   = { class = "kitty" },
    opacity = "1.0 override 1.0 override",
})

local variables = require('variables')
local MONITOR1 = variables.monitor1
local MONITOR2 = variables.monitor2

for _, ws in ipairs({ 1, 2, 3, 4 }) do
  hl.workspace_rule({ workspace = tostring(ws), monitor = MONITOR1 })
end

for _, ws in ipairs({ 5, 6, 7, 8 }) do
  hl.workspace_rule({ workspace = tostring(ws), monitor = MONITOR2 })
end

hl.window_rule({
    match      = { class = "(?i)(^steam_app_|.*game.*)" },
    workspace  = "1",
    no_anim    = true,
    no_blur    = true,
    no_shadow  = true,
    rounding   = 0,
    opacity    = "1.0 override 1.0 override",
    immediate  = true,
    content    = "game",
    fullscreen = true
})
hl.window_rule({
    match     = { content = "game" },
    no_anim   = true,
    no_blur   = true,
    no_shadow = true,
    rounding  = 0,
    opacity   = "1.0 override 1.0 override",
    immediate = true,
})