#!/usr/bin/env bash
#
# Quickshell dotfiles setup. Each step is a module in scripts/ (one file per
# step, sourced in order). With no arguments every step runs in order; pass
# step names to run only those.
#
#   ./setup.sh              # run all steps in order
#   ./setup.sh config fonts # run only these steps
#   ./setup.sh --list       # list step names
#   ./setup.sh --help       # show this help

set -eo pipefail

# curl-piped execution (curl ... | bash) has no local checkout to run from,
# so self-clone into a temp dir once and re-exec from there. Skip this
# entirely when already running from a real checkout -- BASH_SOURCE[0]'s
# directory has scripts/ sitting right next to it -- so a plain ./setup.sh
# uses local edits instead of silently pulling a fresh copy of origin.
if [[ -z "$DOTFILES_CLONED" ]] && { [[ -z "${BASH_SOURCE[0]:-}" ]] || [[ ! -d "$(dirname "${BASH_SOURCE[0]}")/scripts" ]]; }; then
    export DOTFILES_CLONED=1
    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TMP_DIR"' EXIT

    echo "Cloning dotfiles repository..."
    git clone --depth 1 https://github.com/senshu-dev/dotfiles.git "$TMP_DIR"
    cd "$TMP_DIR"
    exec bash setup.sh "$@"
    exit
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load shared helpers + every step module (00-core first by glob order).
for f in "$SCRIPT_DIR"/scripts/*.sh; do
    source "$f"
done

# Steps in run order — single source of truth: "name|function|description".
STEPS=(
    "mirrors|setup_mirrors|Refresh pacman mirrors (reflector)"
    "update|setup_update|Update the system (pacman -Syyu)"
    "packages|setup_packages|Install pacman + AUR packages"
    "remove|setup_remove|Remove unwanted defaults (dolphin) and set Nautilus as default file manager"
    "shell|setup_shell|Set up zsh and oh-my-zsh"
    "config|setup_config|Copy dotfiles .config (hypr, kitty, quickshell, …) into ~/.config"
    "fonts|setup_fonts|Install the AnnotationMono font"
    "extras|setup_extras|Interactive menu: zen browser, bluetooth, VS Code Insiders, podman, binenv, k9s, gaming meta"
)

# Resolve a step name to its function, or fail.
step_fn() {
    local entry name fn
    for entry in "${STEPS[@]}"; do
        IFS='|' read -r name fn _ <<<"$entry"
        if [[ "$name" == "$1" ]]; then
            printf '%s\n' "$fn"
            return 0
        fi
    done
    return 1
}

usage() {
    local entry name fn desc
    cat <<EOF
Usage: $0 [--help] [--list] [step ...]

Runs the Quickshell dotfiles setup. With no arguments, runs all steps in
order. Pass step names to run only those.

Steps:
EOF
    for entry in "${STEPS[@]}"; do
        IFS='|' read -r name fn desc <<<"$entry"
        printf '  %-9s %s\n' "$name" "$desc"
    done
}

run_step() {
    local fn
    if ! fn="$(step_fn "$1")"; then
        error "Unknown step: $1"
        usage
        return 1
    fi
    "$fn"
}

main() {
    local entry name arg

    if [[ $# -eq 0 ]]; then
        for entry in "${STEPS[@]}"; do
            IFS='|' read -r name _ <<<"$entry"
            run_step "$name"
        done
        return
    fi

    for arg in "$@"; do
        case "$arg" in
            --help|-h) usage; return ;;
            --list)    printf '%s\n' "${STEPS[@]%%|*}" ;;
            *)         run_step "$arg" ;;
        esac
    done
}

highlight "Quickshell dotfiles setup"
info "Running as: $USER"
main "$@"
