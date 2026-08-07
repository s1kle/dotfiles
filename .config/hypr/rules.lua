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

-- local MONITOR1 = "eDP-1"
local MONITOR1 = "Virtual-1"
local MONITOR2 = "HDMI-A-1"

for _, ws in ipairs({ 1, 2, 3 }) do
  hl.workspace_rule({ workspace = tostring(ws), monitor = MONITOR1 })
end

for _, ws in ipairs({ 4, 5, 6 }) do
  hl.workspace_rule({ workspace = tostring(ws), monitor = MONITOR2 })
end

hl.window_rule({
    match      = { class = "(?i)(^steam_app_|.*game.*)" },
    workspace = "1",
    no_anim    = true,
    no_blur    = true,
    no_shadow  = true,
    immediate  = true,
    content    = "game",
    fullscreen = true
})
hl.window_rule({
    match     = { content = "game" },
    no_anim   = true,
    no_blur   = true,
    no_shadow = true,
    immediate = true,
})