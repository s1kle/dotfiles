# 20-packages.sh — package installation.

# Packages installed with pacman (one per line makes diffs clean).
PACMAN_PACKAGES=(
    zsh
    zip
    unzip
    uwsm
    playerctl
    brightnessctl
    quickshell
    slurp
    cliphist
    grim
    hyprpolkitagent
    xdg-desktop-portal-hyprland
    hyprlock
    mako
    hypridle
    mpv
    yay
    nautilus
)

AUR_PACKAGES=(
    hyprqt6engine
    hyprmod
    linux-wallpaperengine-git
)

setup_pacman_packages() {
    info "Installing packages with pacman"
    sudo pacman -S --noconfirm "${PACMAN_PACKAGES[@]}"
    ok "Packages installed"
}

setup_aur_packages() {
    info "Installing AUR packages with yay"
    yay -S --noconfirm "${AUR_PACKAGES[@]}"
    ok "AUR packages installed"
}

setup_packages() {
    setup_pacman_packages
    setup_aur_packages
}