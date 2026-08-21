hl.config({
    general = {
        gaps_in  = 10,
        gaps_out = 10,
        border_size = 1,
        resize_on_border = true,
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 4,
        rounding_power = 5,

        active_opacity   = 0.95,
        inactive_opacity = 0.65,

        shadow = {
            enabled         = true,
            range           = 12,
            render_power    = 3,
        },

        blur = {
            enabled           = true,
            size              = 8,
            passes            = 2,
            new_optimizations = true,
            noise             = 0.0117,
            contrast          = 0.8916,
            brightness        = 1.0,
            vibrancy          = 0.1696,
            popups            = true,
        },
    },

    misc = {
        animate_manual_resizes      = true,
        animate_mouse_windowdragging = true,
    },

    cursor = {
        hide_on_key_press = true,
    },

    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
hl.curve("easy",   { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })
hl.curve("bounce", { type = "spring", mass = 1, stiffness = 130,      dampening = 10.5 })

hl.animation({ leaf = "global",             enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",             enabled = true,  speed = 2.5,  bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",            enabled = true,  speed = 4,    spring = "easy",           style = "popin 80%" })
hl.animation({ leaf = "windowsIn",          enabled = true,  speed = 3.5,  spring = "bounce",         style = "popin 80%" })
hl.animation({ leaf = "windowsOut",         enabled = true,  speed = 1.4,  bezier = "linear",         style = "popin 90%" })
hl.animation({ leaf = "windowsMove",        enabled = true,  speed = 3,    spring = "easy" })
hl.animation({ leaf = "fadeIn",             enabled = true,  speed = 2,    bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",            enabled = true,  speed = 1.5,  bezier = "almostLinear" })
hl.animation({ leaf = "fadeSwitch",         enabled = true,  speed = 1.5,  bezier = "almostLinear" })
hl.animation({ leaf = "fadeShadow",         enabled = true,  speed = 1.5,  bezier = "almostLinear" })
hl.animation({ leaf = "fadeGlow",           enabled = true,  speed = 1.5,  bezier = "almostLinear" })
hl.animation({ leaf = "fade",               enabled = true,  speed = 3,    bezier = "quick" })
hl.animation({ leaf = "fadePopups",         enabled = true,  speed = 2,    bezier = "quick" })
hl.animation({ leaf = "layers",             enabled = true,  speed = 3.5,  bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",           enabled = true,  speed = 3,    bezier = "easeOutQuint",   style = "slide" })
hl.animation({ leaf = "layersOut",          enabled = true,  speed = 1.5,  bezier = "linear",         style = "fade" })
hl.animation({ leaf = "fadeLayersIn",       enabled = true,  speed = 2,    bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut",      enabled = true,  speed = 1.5,  bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",         enabled = true,  speed = 3.5,  bezier = "easeOutQuint",   style = "slidefade 17%" })
hl.animation({ leaf = "workspacesIn",       enabled = true,  speed = 2.5,  bezier = "easeOutQuint",   style = "slidefade 17%" })
hl.animation({ leaf = "workspacesOut",      enabled = true,  speed = 1.5,  bezier = "easeOutQuint",   style = "slidefade 17%" })
hl.animation({ leaf = "specialWorkspace",   enabled = true,  speed = 3.5,  bezier = "easeOutQuint",   style = "slidefadevert 17%" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true,  speed = 2.5,  bezier = "easeOutQuint",   style = "slidefadevert 17%" })
hl.animation({ leaf = "specialWorkspaceOut",enabled = true,  speed = 1.5,  bezier = "easeOutQuint",   style = "slidefadevert 17%" })
hl.animation({ leaf = "zoomFactor",         enabled = true,  speed = 7,    bezier = "quick" })

hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 1.0,
    bezier = "default",
})