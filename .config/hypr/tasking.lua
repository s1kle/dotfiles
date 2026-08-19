-- Hyprtasking: workspace-overview plugin (https://github.com/raybbian/hyprtasking).
-- Installed via `hyprpm` (see setup.sh's `setup_hyprtasking`).
--
-- Grid, not linear: linear's overview is one flat strip across ALL
-- workspaces on ALL monitors, so move("right") from ws1 could land on ws5
-- (monitor2) once ws3/ws4 run out, rather than respecting rules.lua's
-- per-monitor workspace_rule binding. Grid's per-view slot assignment
-- filters to only the workspaces bound to that monitor (see grid.cpp's
-- "No two grids may map the same WORKSPACEID" comment), so it can't cross
-- monitors on its own -- that's what move("out") is for. rows=1 cols=4
-- mirrors the existing "flat strip of 4 workspaces per monitor" scheme
-- (keybindings.lua's cycleWs) with zero empty cells.

local variables = require('variables')
local mainMod   = variables.mainMod

hl.bind(mainMod .. " + tab",         function() hl.plugin.hyprtasking.toggle("cursor") end)
hl.bind(mainMod .. " + SHIFT + tab", function() hl.plugin.hyprtasking.toggle("all") end)

-- bare escape closes the overview when it's open, and falls through
-- (non_consuming) to whatever escape normally does otherwise.
hl.bind("escape", function()
    if hl.plugin.hyprtasking.is_active() then
        hl.plugin.hyprtasking.toggle("all")
    end
end, { non_consuming = true })

hl.bind(mainMod .. " + x", function() hl.plugin.hyprtasking.killhovered() end)

hl.bind(mainMod .. " + h",         function() hl.plugin.hyprtasking.move("left") end)
hl.bind(mainMod .. " + l",         function() hl.plugin.hyprtasking.move("right") end)
hl.bind(mainMod .. " + SHIFT + h", function() hl.plugin.hyprtasking.movewindow("left") end)
hl.bind(mainMod .. " + SHIFT + l", function() hl.plugin.hyprtasking.movewindow("right") end)

hl.config({
    plugin = {
        hyprtasking = {
            layout = "grid",

            gap_size = 10,
            -- Nord theme's background (quickshell's default, services/Theme.qml)
            -- at ~90% opacity; static, doesn't follow live theme switching.
            bg_color = 0xe62e3440,
            border_size = 2,
            exit_on_hovered = false,

            grid = {
                rows = 1,
                cols = 4,
                layers = 1,
                loop = true,
                loop_layers = true,
                gaps_use_aspect_ratio = true,
            },
        },
    },
})
