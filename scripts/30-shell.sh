# 30-shell.sh — zsh and oh-my-zsh setup.

setup_shell() {
    info "Setting zsh as default shell"
    sudo chsh "$USER" -s /usr/bin/zsh

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        warn "oh-my-zsh already installed, skipping"
    else
        info "Installing oh-my-zsh"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    info "Setting zsh theme to 'candy'"
    sed -i 's/ZSH_THEME=".*"/ZSH_THEME="candy"/' "$HOME/.zshrc"
    ok "zsh configured"
}
