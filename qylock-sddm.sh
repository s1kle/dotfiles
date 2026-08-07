#!/usr/bin/env bash

# qylock-sddm.sh - Manage qylock SDDM themes
#   list                 list themes, marking [not-]installed/current
#   install <theme>      install theme (downloads from GitHub if missing)

set -eo pipefail

REPO="Darkkal44/qylock"
BRANCH="main"
API_URL="https://api.github.com/repos/${REPO}/contents/themes"
SYSTEM_THEMES_DIR="/usr/share/sddm/themes"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_CONF="${SDDM_CONF_DIR}/theme.conf"

# Colors
C_DIM='\033[38;2;129;122;150m'
C_GREEN='\033[38;2;166;209;137m'
C_YELLOW='\033[38;2;229;200;144m'
C_RED='\033[38;2;231;130;132m'
C_BOLD='\033[1m'
C_RESET='\033[0m'

info()   { echo -e "${C_BOLD}[qylock]${C_RESET} $1"; }
error()  { echo -e "${C_BOLD}[qylock]${C_RED} error:${C_RESET} $1" >&2; }

usage() {
    echo "Usage: $0 <command>"
    echo
    echo "Commands:"
    echo "  list                 List qylock themes (marks installed / current)"
    echo "  install <theme>      Install a theme (downloads from GitHub if needed) and set it active"
}

fetch_remote_themes() {
    curl -fsSL "$API_URL" 2>/dev/null | grep -oE '"name": *"[^"]+"' \
        | sed -E 's/"name": *"([^"]+)"/\1/' || true
}

current_theme() {
    local current=""
    if [ -f "$SDDM_CONF" ]; then
        current=$(grep -E '^\s*Current\s*=' "$SDDM_CONF" | head -n1 | sed -E 's/^\s*Current\s*=\s*//' | tr -d '[:space:]')
    fi
    if [ -n "$current" ] && [ -d "$SYSTEM_THEMES_DIR/$current" ]; then
        echo "$current"
    fi
}

list_themes() {
    local -A status
    local themes=()
    local installed=()

    if ! command -v curl >/dev/null 2>&1; then
        error "curl is required"
        exit 1
    fi

    info "Fetching themes from ${REPO}..."
    mapfile -t themes < <(fetch_remote_themes)
    if [ "${#themes[@]}" -eq 0 ]; then
        info "${C_YELLOW}Could not reach GitHub (offline?). Showing installed themes only.${C_RESET}"
    fi

    [ -d "$SYSTEM_THEMES_DIR" ] && mapfile -t installed < <(ls -1 "$SYSTEM_THEMES_DIR" 2>/dev/null)

    local current
    current=$(current_theme)

    for t in "${installed[@]}"; do
        if [ -z "${status[$t]:-}" ]; then
            status[$t]="installed"
        fi
    done
    for t in "${themes[@]}"; do
        if [ -n "${status[$t]:-}" ]; then
            continue
        fi
        if [ -d "$SYSTEM_THEMES_DIR/$t" ]; then
            status[$t]="installed"
        else
            status[$t]="remote"
        fi
    done

    echo
    local sorted
    mapfile -t sorted < <(printf '%s\n' "${!status[@]}" | sort)
    for t in "${sorted[@]}"; do
        if [ "$t" = "$current" ]; then
            echo -e "  ${C_GREEN}●${C_RESET} ${C_BOLD}$t${C_RESET}  ${C_YELLOW}(current)${C_RESET}"
        elif [ "${status[$t]}" = "installed" ]; then
            echo -e "  ${C_GREEN}✓${C_RESET} $t  ${C_DIM}(installed)${C_RESET}"
        else
            echo -e "  ${C_DIM}·${C_RESET} $t  ${C_DIM}(not installed)${C_RESET}"
        fi
    done
    echo

    if [ -n "$current" ]; then
        info "Active theme: ${C_BOLD}${C_YELLOW}${current}${C_RESET}"
    else
        info "No active theme set."
    fi
}

install_theme() {
    local theme="$1"
    local dest="$SYSTEM_THEMES_DIR/$theme"
    local tmp
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' RETURN

    if ! command -v git >/dev/null 2>&1; then
        error "git is required"
        exit 1
    fi

    if [ -d "$dest" ]; then
        info "Theme '${theme}' is already installed. Reinstalling from GitHub..."
    else
        info "Theme '${theme}' is not installed. Downloading from ${REPO}..."
    fi

    git clone --quiet --depth 1 --filter=blob:none --sparse \
        "https://github.com/${REPO}.git" "$tmp/qylock" || {
        error "Failed to download repository"
        exit 1
    }
    if ! git -C "$tmp/qylock" sparse-checkout set "themes/${theme}" 2>/dev/null; then
        error "Theme '${theme}' not found in repository"
        exit 1
    fi
    if [ ! -d "$tmp/qylock/themes/${theme}" ]; then
        error "Theme '${theme}' not found in repository"
        exit 1
    fi
    info "Downloaded."

    info "Installing to ${dest}..."
    sudo mkdir -p "$SYSTEM_THEMES_DIR"
    if [ -d "$dest" ]; then
        sudo rm -rf "$dest"
    fi
    sudo cp -r "$tmp/qylock/themes/${theme}" "$dest"

    info "Setting '${theme}' as active theme..."
    sudo mkdir -p "$SDDM_CONF_DIR"
    if grep -q '^\s*Current\s*=' "$SDDM_CONF" 2>/dev/null; then
        sudo sed -i -E "s|^\s*Current\s*=.*|Current=${theme}|" "$SDDM_CONF"
    elif grep -q '^\s*\[Theme\]' "$SDDM_CONF" 2>/dev/null; then
        sudo sed -i "/^\s*\[Theme\]/a Current=${theme}" "$SDDM_CONF"
    else
        printf '\n[Theme]\nCurrent=%s\n' "$theme" | sudo tee -a "$SDDM_CONF" >/dev/null
    fi

    info "Done. Theme '${C_BOLD}${C_YELLOW}${theme}${C_RESET}' is now active."
    info "Fonts: check ${dest}/font/ and the qylock README for optional fonts."
}

main() {
    local cmd="${1:-}"

    case "$cmd" in
        list)
            list_themes
            ;;
        install)
            [ $# -ge 2 ] || { usage; exit 1; }
            install_theme "$2"
            ;;
        -h|--help|help)
            usage
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
