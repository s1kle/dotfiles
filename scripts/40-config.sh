# 40-config.sh — copies the entire .config directory into ~/.config.
#
# The .config directory lives next to this script (../.config). It
# resolves its own path so it works no matter where setup.sh is invoked
# from.

setup_config() {
    local scripts_dir config_dir
    scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    config_dir="$scripts_dir/../.config"

    if [[ ! -d "$config_dir" ]]; then
        warn ".config not found at '$config_dir', skipping"
        return 0
    fi

    info "Installing .config"
    mkdir -p "$HOME/.config"
    cp -r "$config_dir/." "$HOME/.config/"
    ok ".config installed"
}
