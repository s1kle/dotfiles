hl.on("hyprland.start", function ()
    hl.exec_cmd("quickshell")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wl-paste --watch cliphist store &") -- feeds the sidebar clipboard-history tile
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &")
    hl.exec_cmd("linux-wallpaperengine --disable-mouse --fullscreen-pause-only-active --no-audio-processing --disable-parallax --fps 30 --scaling stretch --screen-root eDP-1 --bg $(ls -d ~/.steam/steam/steamapps/workshop/content/431960/* | xargs -n 1 basename | shuf -n 1)")
end)
