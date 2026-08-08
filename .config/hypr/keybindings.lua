local programs = require('programs')

local mainMod      = "SUPER"
local launchPrefix = "uwsm app -- "

hl.bind(mainMod .. " + backspace",        hl.dsp.exec_cmd(launchPrefix .. programs.terminal))
hl.bind(mainMod .. " + t",        hl.dsp.exec_cmd("qs ipc thememenu toggle"))
hl.bind("PRINT", hl.dsp.exec_cmd('grim -g "$(slurp)" - | tee ~/screenshot_$(date +%Y%m%d_%H%M%S).png | wl-copy'))
hl.bind(mainMod .. " + l", hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))
hl.bind(mainMod .. " + space",    hl.dsp.exec_cmd(launchPrefix .. programs.menu))
hl.bind("CTRL + SHIFT + ESCAPE",        hl.dsp.exec_cmd(launchPrefix .. programs.terminal .. " -e btop"))
hl.bind(mainMod .. "s",        hl.dsp.exec_cmd('grim -g "$(slurp)" - | tee ~/screenshot_$(date +%Y%m%d_%H%M%S).png | wl-copy'))
hl.bind(mainMod .. "e",        hl.dsp.exec_cmd(launchPrefix .. programs.fileManager))
hl.bind(mainMod .. "escape",   hl.dsp.exec_cmd("hyprctl reload"))

hl.bind(mainMod .. " + c",                hl.dsp.window.close())
hl.bind(mainMod .. " + q",                hl.dsp.window.close())
hl.bind(mainMod .. " + ALT + space",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + d",                hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + f",                hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + b",                hl.dsp.window.pseudo())
hl.bind(mainMod .. " + j",                hl.dsp.layout("togglesplit"))
hl.bind("ALT + tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)
hl.bind(mainMod .. " + mouse:272",        hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:274",        hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + mouse:273",        hl.dsp.window.resize())

hl.bind(mainMod .. " + mouse_down",        hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
hl.bind(mainMod .. " + mouse_up",        hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
hl.bind(mainMod .. " + CONTROL + mouse_down",        hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
hl.bind(mainMod .. " + CONTROL + mouse_up",        hl.dsp.window.resize({ x = 0, y = 100, relative = true }))


hl.bind("ALT + SPACE", hl.dsp.submap("focus"))
hl.define_submap("focus", function ()
    hl.bind("left",             hl.dsp.focus({ direction = "left" }))
    hl.bind("right",            hl.dsp.focus({ direction = "right" }))
    hl.bind("up",               hl.dsp.focus({ direction = "up" }))
    hl.bind("down",             hl.dsp.focus({ direction = "down" }))

    hl.bind("escape", hl.dsp.submap("reset"))
end)


hl.bind(mainMod .. " + right",      hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + left",       hl.dsp.focus({ workspace = "e-1" }))

for i = 1, 6 do
    hl.bind(mainMod .. " + " .. i,        hl.dsp.focus({ workspace = i }))
end


  -- ================================ --
  --           HARDWARE               --
  -- ================================ --

  -- Audio
hl.bind("XF86AudioRaiseVolume",           hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",           hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),       { locked = true, repeating = true })
hl.bind("XF86AudioMute",                  hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),      { locked = true })
hl.bind("XF86AudioMicMute",               hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),    { locked = true })

  -- Brightness
hl.bind("XF86MonBrightnessUp",            hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",          hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                   { locked = true, repeating = true })

  -- Media control
hl.bind("XF86AudioNext",                  hl.dsp.exec_cmd("playerctl next"),          { locked = true })
hl.bind("XF86AudioPause",                 hl.dsp.exec_cmd("playerctl play-pause"),    { locked = true })
hl.bind("XF86AudioPlay",                  hl.dsp.exec_cmd("playerctl play-pause"),    { locked = true })  -- duplicate of Pause
hl.bind("XF86AudioPrev",                  hl.dsp.exec_cmd("playerctl previous"),      { locked = true })
