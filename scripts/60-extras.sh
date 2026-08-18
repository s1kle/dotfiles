# 60-extras.sh — optional extras, chosen interactively.
#
# setup_extras() shows a menu of every extra: SPACE toggles, arrows
# move, ENTER installs, q quits. Everything is selected by default.
# When input isn't interactive (piped), everything is installed.

# One entry per extra; the entry is the suffix of its setup_ function.
EXTRAS=(
    zen
    bluetooth
    vscode
    podman
    binenv
    k9s
    gaming
    xray
)

setup_extras() {
    local -a chosen=()
    local entry i=0 j key key2 cursor checked
    for entry in "${EXTRAS[@]}"; do
        chosen+=("1")
    done

    while :; do
        printf 'Extra packages (SPACE: toggle, arrows: move, ENTER: install, q: quit)\n'
        for ((j = 0; j < ${#EXTRAS[@]}; j++)); do
            cursor=' '
            checked=' '
            [[ $j -eq $i ]] && cursor='>'
            [[ ${chosen[j]} -eq 1 ]] && checked=x
            printf ' %s [%s] %s\n' "$cursor" "$checked" "${EXTRAS[j]}"
        done
        IFS= read -rsn1 key || key=''
        case "$key" in
            ' ') chosen[i]=$((1 - chosen[i])) ;;
            $'\e') key2=''
                   IFS= read -rsn2 -t 0.2 key2 || true
                   case "$key2" in
                       '[A') i=$((i - 1)) ;;
                       '[B') i=$((i + 1)) ;;
                   esac ;;
            '') break ;;
            q) printf '\n'; return 0 ;;
        esac
        i=$(((i + ${#EXTRAS[@]}) % ${#EXTRAS[@]}))
        printf '\e[%dA' "$(( ${#EXTRAS[@]} + 1 ))"
    done

    printf '\n'
    for ((j = 0; j < ${#EXTRAS[@]}; j++)); do
        if [[ ${chosen[j]} -eq 1 ]]; then
            info "Installing ${EXTRAS[j]}"
            "setup_${EXTRAS[j]}"
        fi
    done
}

setup_zen() {
    local url tmp archive binary
    url="https://github.com/zen-browser/desktop/releases/download/1.21.10b/zen.linux-x86_64.tar.xz"
    tmp="$(mktemp -d)"
    archive="$tmp/archive"
    info "Downloading zen browser"
    curl -fL "$url" -o "$archive"
    case "$archive" in
        *.zip) unzip -q "$archive" -d "$tmp" ;;
        *) tar -xf "$archive" -C "$tmp" ;;
    esac
    binary="$(find "$tmp" -type f -name "zen" -perm -u+x | head -n1)"
    # zen's launcher needs its runtime dir next to the binary
    sudo rm -rf /opt/zen
    sudo mkdir -p /opt/zen
    sudo cp -r "$(dirname "$binary")/." /opt/zen/
    sudo ln -sf /opt/zen/"$(basename "$binary")" /usr/local/bin/zen
    # the tarball ships no .desktop; the only one the browser autogenerates is
    # NoDisplay=true, so it never shows in launchers — write a real one.
    sudo tee /usr/share/applications/zen.desktop >/dev/null <<'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Zen Browser
Comment=Experience tranquillity while browsing the web
Exec=/opt/zen/zen %u
Icon=/opt/zen/browser/chrome/icons/default/default128.png
Terminal=false
StartupNotify=true
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
DESKTOP
    rm -rf "$tmp"
    ok "zen installed"
}

setup_bluetooth() {
    info "Enabling bluetooth.service"
    sudo systemctl enable --now bluetooth
    ok "bluetooth.service enabled"
}

setup_vscode() {
    info "Installing VS Code Insiders"
    yay -S --noconfirm visual-studio-code-insiders-bin
    ok "VS Code Insiders installed"
}

setup_podman() {
    info "Installing podman"
    sudo pacman -S --noconfirm podman podman-compose
    # tools that hardcode "docker" (compose plugins, CI scripts, ...) work unmodified.
    sudo tee /usr/local/bin/docker >/dev/null <<'SCRIPT'
#!/usr/bin/env bash
exec podman "$@"
SCRIPT
    sudo chmod +x /usr/local/bin/docker
    ok "podman installed (docker -> podman shim at /usr/local/bin/docker)"
}

setup_binenv() {
    info "Installing binenv"
    wget -q https://github.com/devops-works/binenv/releases/download/v0.19.11/binenv_linux_amd64
    wget -q https://github.com/devops-works/binenv/releases/download/v0.19.11/checksums.txt
    sha256sum  --check --ignore-missing checksums.txt
    mv binenv_linux_amd64 binenv
    chmod +x binenv
    ./binenv update
    ./binenv install binenv
    rm binenv
    if [[ -n $BASH ]]; then ZESHELL=bash; fi
    if [[ -n $ZSH_NAME ]]; then ZESHELL=zsh; fi
    echo $ZESHELL
    echo -e '\nexport PATH=~/.binenv:$PATH' >> ~/.${ZESHELL}rc
    echo "source <(binenv completion ${ZESHELL})" >> ~/.${ZESHELL}rc
    exec $SHELL
    ok "binenv installed"
}

setup_k9s() {
    info "Installing k9s"
    yay -S --noconfirm k9s
    ok "k9s installed"
}

# Requires the CachyOS repos in pacman.conf (https://wiki.cachyos.org/cachyos_repo/) --
# not part of vanilla Arch, so this is opt-in rather than a pacman-packages entry.
setup_gaming() {
    info "Installing CachyOS gaming meta packages"
    sudo pacman -S --noconfirm cachyos-gaming-meta cachyos-gaming-applications
    ok "Gaming packages installed"
}

# Xray-core (VLESS client, driven headlessly by scripts/xray-instance.sh).
# No packaged build exists that isn't bundled for some unrelated panel
# project, so this builds from source. Pinned to a specific commit rather
# than `go install .../main@latest`: @latest resolved to tagged release
# 26.3.27, whose tun inbound silently produced a non-functional route (no
# error, device came up, but traffic never actually reached the outbound) --
# this commit is the one actually verified end-to-end (clean TLS handshake,
# confirmed egress via the VPN server's own IP). Bump it deliberately, not
# casually -- re-verify tun mode before trusting a newer commit.
#
# Needs cap_net_admin to create/route its own tun device as a non-root user
# for tun mode; since this binary isn't pacman-managed there's no upgrade
# hook to reapply it automatically -- re-run this (or at least the setcap
# line) after rebuilding.
XRAY_VERIFIED_COMMIT=7d214f8b094f75322fa3990f8aadad1c912f24f5
setup_xray() {
    local tmp
    info "Installing xray-core (built from source, pinned commit)"
    tmp="$(mktemp -d)"
    git clone -q https://github.com/XTLS/Xray-core "$tmp/xray-core"
    (cd "$tmp/xray-core" && git checkout -q "$XRAY_VERIFIED_COMMIT" \
        && go build -o "$HOME/.local/bin/xray" -trimpath ./main)
    rm -rf "$tmp"
    sudo setcap cap_net_admin+ep "$HOME/.local/bin/xray"
    ok "xray installed, cap_net_admin granted"
}
