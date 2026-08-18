#!/usr/bin/env bash
# Headless control of an Xray-core VLESS tunnel for quickshell/hyprland,
# driven as transient systemd --user units so it survives disconnects.
#
# tun   -- full system-wide capture via Xray's own native tun inbound.
#          (Not a bolted-on third-party bridge like tun2socks/badvpn --
#          those corrupted TLS handshakes through this system's NM-created
#          tun devices regardless of MTU/vnet-hdr tuning or which SOCKS
#          backend was behind them; Xray's own tun integration doesn't have
#          that problem.) Xray creates the device and programs routes itself,
#          no NetworkManager/polkit setup needed.
# proxy -- local SOCKS5/HTTP inbounds + the GNOME system-proxy gsetting, for
#          apps that don't need full capture.
#
# tun and proxy run as independent units (xray-instance-tun / -proxy), so
# `stop`/`status` can target one without touching the other -- but `start`
# always stops the opposite mode first: switching should replace, not stack.
#
# Configs (server address, VLESS credentials) live in $RUNDIR/*.json,
# deliberately outside the git-tracked dotfiles tree -- bare credentials, not
# something to commit. See scripts/60-extras.sh's setup_xray() for the
# one-time cap_net_admin grant tun mode needs.
set -euo pipefail

# quickshell's process spawning doesn't reliably forward DBUS_SESSION_BUS_ADDRESS,
# which gsettings (proxy mode) needs to reach dconf -- reconstruct the
# standard systemd/logind per-user bus path if it's missing rather than
# silently no-op'ing the gsettings calls below.
: "${DBUS_SESSION_BUS_ADDRESS:=unix:path=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus}"
export DBUS_SESSION_BUS_ADDRESS

CLI="$HOME/.local/bin/xray"
RUNDIR="$HOME/.local/state/xray-instance"
TUN_CONFIG="$RUNDIR/tun-config.json"
PROXY_CONFIG="$RUNDIR/proxy-config.json"
SOCKS_PORT=10808
HTTP_PORT=10809

usage() { echo "usage: $0 start tun|proxy|stop [tun|proxy]|status [tun|proxy]" >&2; exit 1; }

unit_for() { echo "xray-instance-$1"; }
lock_for() { echo "$RUNDIR/lock-$1"; }

# do_stop and do_start are called from within each other (do_start stops the
# opposite mode before starting its own) -- every variable here MUST be
# `local`. Without it, do_stop's `mode=$1; unit=...` clobbers do_start's own
# mode/unit out from under it once do_stop returns, since bash functions
# share the caller's scope by default. (Learned this the hard way: it
# silently ran the proxy config under the tun unit name.)
do_stop() {
    local mode=$1 unit
    unit=$(unit_for "$mode")
    exec 9>"$(lock_for "$mode")"
    flock 9
    systemctl --user stop "$unit" >/dev/null 2>&1 || true
    if [ "$mode" = proxy ]; then
        gsettings set org.gnome.system.proxy mode none
    fi
}

do_start() {
    local mode=$1 unit config other ready
    unit=$(unit_for "$mode")
    config=$TUN_CONFIG
    [ "$mode" = proxy ] && config=$PROXY_CONFIG
    [ -f "$config" ] || { echo "xray-instance: missing $config" >&2; exit 1; }

    # Switching modes (e.g. quickshell's toggleMode) should replace, not
    # stack: proxy mode can't carry a connection established under tun's
    # system-wide capture anyway, so leaving both up just wastes a tunnel.
    other=$([ "$mode" = tun ] && echo proxy || echo tun)
    do_stop "$other"

    exec 9>"$(lock_for "$mode")"
    flock 9
    systemctl --user stop "$unit" >/dev/null 2>&1 || true
    systemctl --user reset-failed "$unit" >/dev/null 2>&1 || true
    systemd-run --user --collect --unit="$unit" \
        "$CLI" run -c "$config" >/dev/null 2>&1

    ready=
    for _ in $(seq 1 25); do
        systemctl --user is-active --quiet "$unit" || break
        journalctl --user -u "$unit" --since "-5 seconds" --no-pager 2>/dev/null \
            | grep -qE "Xray [0-9.]+ started" && { ready=1; break; }
        sleep 0.2
    done
    [ -n "$ready" ] || {
        echo "xray-instance: $mode failed to start (see: journalctl --user -u $unit)" >&2
        systemctl --user stop "$unit" >/dev/null 2>&1 || true
        exit 1
    }

    if [ "$mode" = proxy ]; then
        # GNOME's system-proxy schema has separate host/port per protocol
        # (http/https/ftp/socks) -- an app in "manual" mode reads whichever
        # one matches its own traffic, not just .socks. Stale .http/.https
        # values from a since-removed proxy (different app, different port)
        # silently pointed browsers at a dead port even with mode=manual and
        # .socks correctly set -- set every protocol so nothing's stale.
        local proto
        for proto in http https socks; do
            gsettings set "org.gnome.system.proxy.$proto" host 127.0.0.1
            gsettings set "org.gnome.system.proxy.$proto" port "$([ "$proto" = socks ] && echo "$SOCKS_PORT" || echo "$HTTP_PORT")"
        done
        gsettings set org.gnome.system.proxy mode manual
    fi
}

mkdir -p "$RUNDIR"

case "${1:-}" in
    start)
        mode=${2:-tun}
        [ "$mode" = tun ] || [ "$mode" = proxy ] || usage
        do_start "$mode"
        ;;
    stop)
        mode=${2:-}
        if [ -z "$mode" ]; then
            do_stop tun
            do_stop proxy
        else
            [ "$mode" = tun ] || [ "$mode" = proxy ] || usage
            do_stop "$mode"
        fi
        ;;
    status)
        mode=${2:-}
        if [ -z "$mode" ]; then
            # bare status (quickshell's poll): "active" if either is up.
            if systemctl --user is-active --quiet "$(unit_for tun)"; then
                echo active
            elif systemctl --user is-active --quiet "$(unit_for proxy)"; then
                echo active
            else
                echo inactive
            fi
        else
            [ "$mode" = tun ] || [ "$mode" = proxy ] || usage
            systemctl --user is-active "$(unit_for "$mode")" 2>/dev/null || true
        fi
        ;;
    *)
        usage
        ;;
esac
