#!/usr/bin/env bash
# Apply the active quickshell theme's variant (dark/light) system-wide.
#
# Sets the GNOME/GTK color-scheme -- which xdg-desktop-portal exposes as
# org.freedesktop.appearance color-scheme -- so every color-scheme-aware app
# follows: GTK4/libadwaita, GTK3 (via gtk-theme), Firefox, Chromium, and Qt
# platform themes that honour the portal (hyprqt6engine). Full per-app palette
# theming isn't portable across toolkits; the light/dark variant is.
#
# Resolves the variant itself (config.json deep-merged with the host file, then
# the theme JSON), so it's independent of quickshell's load order.
set -euo pipefail
QS="$HOME/.config/quickshell"

variant=$(python3 - <<PY
import json, os, socket
base = json.load(open(os.path.join("$QS", "config.json"))).get("theme", {}).get("name", "Nord")
host = os.path.join("$QS", "config.%s.json" % socket.gethostname())
name = json.load(open(host)).get("theme", {}).get("name", base) if os.path.isfile(host) else base
print(json.load(open(os.path.join("$QS", "themes", name + ".json"))).get("variant", "dark"))
PY
)

case "$variant" in
    light) scheme=prefer-light ;;
    *)     scheme=prefer-dark ;;
esac

# color-scheme is the portable signal: GTK4/libadwaita apps (and portal-aware
# apps) follow it live. GTK3 doesn't read it and Qt/KDE need their own scheme
# machinery -- prefer libadwaita apps (e.g. nautilus) for reliable following.
gsettings set org.gnome.desktop.interface color-scheme "$scheme"
echo "theme-variant: applied $variant ($scheme)"
