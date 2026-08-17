# 10-system.sh — system preparation: mirrors and update.
#
# reflector doesn't understand CachyOS's separate cachyos-mirrorlist, so we
# use CachyOS's own tool instead -- it ranks both the Arch and CachyOS
# mirrorlists (plus CPU-optimized v3/v4 variants for the latter) in one go.

setup_mirrors() {
    info "Ranking Arch + CachyOS mirrors"
    sudo pacman -S --needed --noconfirm cachyos-rate-mirrors
    sudo cachyos-rate-mirrors
    ok "Mirrorlists updated"
}

setup_update() {
    info "Updating system"
    sudo pacman -Syyu --noconfirm
    ok "System updated"
}
