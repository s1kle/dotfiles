#!/usr/bin/env bash
# Picks a random wallpaper for both monitors from the local dharmx/walls
# mirror (github.com/dharmx/walls; downloaded by the `wallpapers` extra in
# scripts/60-extras.sh) and restarts hyprpaper to show it. Run at login by
# autostart.lua.
#
# For picking a *specific* wallpaper (with previews, browsable by category
# folder) use waypaper instead -- SUPER+w opens it, and it drives the same
# hyprctl hyprpaper IPC itself once you pick one.
set -euo pipefail

WALLS_DIR="$HOME/walls"
MONITOR1="DP-1"
MONITOR2="HDMI-A-1"
SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.hyprpaper.sock"

pkill -x hyprpaper 2>/dev/null || true
sleep 0.3
rm -f "$SOCK"  # hyprpaper doesn't reliably unlink its own socket on exit; a stale
                # one left over blocks the next instance from binding and sends it
                # into a busy-fail spin instead of erroring cleanly.
hyprpaper >/tmp/hyprpaper.log 2>&1 &
disown

for _ in $(seq 1 50); do
    [ -S "$SOCK" ] && break
    sleep 0.1
done

img=$(find "$WALLS_DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | shuf -n 1)
hyprctl hyprpaper wallpaper "$MONITOR1,$img"
hyprctl hyprpaper wallpaper "$MONITOR2,$img"
