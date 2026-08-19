-- Hyprtasking: workspace-overview plugin (https://github.com/raybbian/hyprtasking).
-- Installed via `hyprpm` (see setup.sh's `setup_hyprtasking`).
--
-- Linear layout, not grid: this repo cycles a flat strip of 4 workspaces per
-- monitor (see keybindings.lua's cycleWs), so a 2D grid would leave most
-- cells empty -- linear mirrors that existing scheme directly.

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
            layout = "linear",

            gap_size = 10,
            -- Nord theme's background (quickshell's default, services/Theme.qml)
            -- at ~90% opacity; static, doesn't follow live theme switching.
            bg_color = 0xe62e3440,
            border_size = 2,
            exit_on_hovered = false,

            linear = {
                top = false,
                height = 400,
                scroll_speed = 1.0,
                blur = false,
            },
        },
    },
})
