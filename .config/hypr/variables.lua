-- User-tunable settings shared across the hypr/*.lua config: programs to
-- launch, the keybind modifier, and monitor output names. Central place to
-- edit when moving to a new host or monitor layout.

local variables = {
    mainMod      = "SUPER",
    launchPrefix = "uwsm app -- ",

    programs = {
        terminal    = "kitty",
        fileManager = "nautilus",
        menu        = "qs ipc call appmenu open",
    },

    -- Output names driving workspace assignment (rules.lua) and per-monitor
    -- workspace cycling (keybindings.lua). monitor1 was "eDP-1" on the laptop.
    monitor1 = "Virtual-1",
    monitor2 = "HDMI-A-1",
}

return variables
