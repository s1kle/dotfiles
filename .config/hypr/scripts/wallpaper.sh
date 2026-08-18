#!/usr/bin/env bash
# Swaps live linux-wallpaperengine scenes (continuous ~40% iGPU + ~10% CPU,
# they fully re-render every frame even when nothing's animating) for
# hyprpaper showing a pre-rendered frame (~0% once loaded). Frames are
# exported once via `linux-wallpaperengine --screenshot` into
# ~/.config/wallpapers-static; see export_wpe_shots.sh. Picks a random one per
# login, same feel as the old `shuf -n 1` over the workshop dir.
set -euo pipefail

WALLPAPER_DIR="$HOME/.config/wallpapers-static"
MONITOR="eDP-1"
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

img=$(find "$WALLPAPER_DIR" -name '*.png' | shuf -n 1)
hyprctl hyprpaper wallpaper "$MONITOR,$img"
