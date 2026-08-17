require('monitor')
require('autostart')
require('hyprenv')
require('keybindings')
require('rules')
require('visual')

hl.config({
    decoration = {
        blur = {
            size = 5,
        },
        fullscreen_opacity = 0.8,
        rounding = 10,
        shadow = {
            offset = "2 2",
            range = 14,
        },
    },
    ecosystem = {
        no_donation_nag = true,
        no_update_news = true,
    },
    general = {
        extend_border_grab_area = 30,
        gaps_in = 5,
        allow_tearing = true,
    },
    misc = {
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    scrolling = {
        fullscreen_on_one_column = true,
    },
    xwayland = {
        force_zero_scaling = true
    },

    input = {
        kb_layout  = "us,ru",
        kb_variant = ",",
        kb_model   = "",
        kb_options = "grp:alt_shift_toggle",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0,

        touchpad = {
            natural_scroll = true,
        },
    },
    
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 2, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 2, direction = "down",       action = "float" })

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

-- HyprMod managed settings
require("hyprland-gui")
