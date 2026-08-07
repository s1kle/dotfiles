# 00-core.sh — shared helpers: colors and logging.
#
# Sourced by setup.sh and every module. Defines no setup steps itself.
# Colors are only emitted when output is a terminal (no garbage in logs).

if [[ -t 1 ]]; then
    readonly CYAN=$'\033[0;36m'
    readonly GREEN=$'\033[0;32m'
    readonly YELLOW=$'\033[0;33m'
    readonly RED=$'\033[0;31m'
    readonly NC=$'\033[0m'
else
    readonly CYAN='' GREEN='' YELLOW='' RED='' NC=''
fi

# Section titles (e.g. "Installing packages").
highlight() { printf '%b%s%b\n' "$CYAN" "$*" "$NC"; }

# Step progress.
info()  { printf '%b[ info ]:%b %s\n' "$CYAN" "$NC" "$*"; }

# Step completed successfully.
ok()    { printf '%b[ ok ]:%b %s\n' "$GREEN" "$NC" "$*"; }

# Non-fatal problems (skipped steps, already installed, ...).
warn()  { printf '%b[ warn ]:%b %s\n' "$YELLOW" "$NC" "$*" >&2; }

# Fatal problems.
error() { printf '%b[ error ]:%b %s\n' "$RED" "$NC" "$*" >&2; }
