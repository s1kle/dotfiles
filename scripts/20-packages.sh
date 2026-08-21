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
    wf-recorder        # sidebar recording tile
    hyprpolkitagent
    xdg-desktop-portal-hyprland
    hyprlock
    hyprpaper
    hyprsunset
    mako
    hypridle
    mpv
    imv                # default image viewer (screenshot tile, nautilus)
    yay
    qt6-5compat
    libcanberra        # canberra-gtk-play: volume-change blip in the sidebar
    pacman-contrib     # checkupdates: sidebar update-count tile
    socat              # sidebar submap indicator: reads the Hyprland event socket
    nautilus
    gvfs               # trash, mounting drives, network shares
    file-roller        # archive extract/create integration
    tumbler            # thumbnailing service
    ffmpegthumbnailer  # video thumbnails for tumbler
    nautilus-python    # base for python nautilus extensions
    libnetfilter_queue
    bluez              # bluetoothd; services/Bluetooth.qml talks to it over D-Bus
    bluez-utils        # bluetoothctl (CLI), bluetuith's backend
    waypaper           # wallpaper picker with thumbnail previews, SUPER+w
)

AUR_PACKAGES=(
    hyprqt6engine
    hyprmod
    nautilus-open-any-terminal  # "Open Terminal Here" -> kitty
    bluetuith                   # TUI bluetooth manager, sidebar bluetooth tile left-click
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