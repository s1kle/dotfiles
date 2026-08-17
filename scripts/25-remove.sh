# 25-remove.sh — remove unwanted default packages and set app defaults.
#
# Some packages ship with the base OS install that we don't want (e.g. Dolphin,
# a KDE app that ignores the freedesktop color-scheme so it can't follow the
# light/dark theme switch). We drop those and make Nautilus the file manager,
# which is libadwaita and does follow the variant.

# Removed if present (safe to list packages that may not be installed).
REMOVE_PACKAGES=(
    dolphin
)

setup_remove() {
    info "Removing unwanted default packages"
    local pkg present=()
    for pkg in "${REMOVE_PACKAGES[@]}"; do
        pacman -Qq "$pkg" &>/dev/null && present+=("$pkg")
    done
    if ((${#present[@]})); then
        sudo pacman -Rns --noconfirm "${present[@]}"
        ok "Removed: ${present[*]}"
    else
        warn "No listed packages present to remove"
    fi

    # Nautilus as the default file manager (replaces Dolphin for opening folders).
    if command -v xdg-mime &>/dev/null; then
        xdg-mime default org.gnome.Nautilus.desktop inode/directory
        ok "Default file manager set to Nautilus"

        # imv as the default image viewer — Nautilus otherwise has no app
        # registered for image mimetypes.
        for mime in image/png image/jpeg image/gif image/webp image/bmp; do
            xdg-mime default imv.desktop "$mime"
        done
        ok "Default image viewer set to imv"
    else
        warn "xdg-mime not found; skipped setting default file manager"
    fi

    # Point nautilus-open-any-terminal's "Open Terminal Here" at kitty.
    if gsettings list-schemas 2>/dev/null | grep -q nautilus-open-any-terminal; then
        gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal kitty
        ok "Nautilus 'Open Terminal Here' set to kitty"
    fi
}
