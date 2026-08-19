hl.on("hyprland.start", function ()
    -- hyprpm doesn't auto-load enabled plugins into a fresh Hyprland
    -- instance on its own -- without this, tasking.lua's binds call into
    -- a nil hl.plugin.hyprtasking and error out the moment they fire.
    hl.exec_cmd("hyprpm reload -n")
    hl.exec_cmd("quickshell")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wl-paste --watch cliphist store &") -- feeds the sidebar clipboard-history tile
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &")
    -- live wallpaperengine scene (heavier, animated) vs. pre-rendered hyprpaper frame
    -- (near-0% idle, see scripts/wallpaper.sh) -- comment one, uncomment the other
    -- hl.exec_cmd("linux-wallpaperengine --disable-mouse --fullscreen-pause-only-active --no-audio-processing --disable-parallax --fps 30 --scaling stretch --screen-root eDP-1 --bg $(ls -d ~/.steam/steam/steamapps/workshop/content/431960/* | xargs -n 1 basename | shuf -n 1)")
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper.sh")
end)
