#!/usr/bin/env bash
# Cycle <monitor>'s active workspace within [start,end], wrapping numerically
# (1-2-3-1) regardless of whether the target workspace has windows -- unlike
# Hyprland's built-in +1/-1 which is occupancy-aware.
# Args: <monitor> <start> <end> <+1|-1>
set -euo pipefail
monitor="$1" start="$2" end="$3" dir="$4"

cur=$(hyprctl monitors | awk -v m="$monitor" '
    $0 ~ ("^Monitor " m " ") { f = 1 }
    f && /active workspace:/  { print $3; exit }
')

span=$((end - start + 1))
next=$(( (cur - start + dir + span) % span + start ))
# plain "hyprctl dispatch workspace <id>" gets parsed as Lua on this
# HyprMod build (config is Lua-driven); route through its hl.dsp API instead.
hyprctl dispatch "hl.dsp.focus({ workspace = $next })"
