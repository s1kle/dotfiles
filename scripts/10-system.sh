# 10-system.sh — system preparation: mirrors and update.

setup_mirrors() {
    info "Finding top 10 mirrors"
    sudo reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    ok "Mirrorlist updated"
}

setup_update() {
    info "Updating system"
    sudo pacman -Syyu --noconfirm
    ok "System updated"
}
