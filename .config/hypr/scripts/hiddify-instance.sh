#!/usr/bin/env bash
# Headless control of Hiddify's proxy core, bypassing its GUI app (Flutter,
# needs a display we don't have over SSH/from quickshell). Runs the same
# HiddifyCli binary the GUI shells out to, against whichever profile Hiddify
# itself has marked active, as a transient systemd --user unit so it survives
# disconnects. `stop` sends SIGTERM, which HiddifyCli catches and uses to
# cleanly tear down the tun route / system-proxy gsetting it set up.
#
# Needs the one-time NetworkManager tun permission setup from
# hiddify_tun_nonroot.sh for --tun mode to work non-root.
set -euo pipefail

UNIT=hiddify-instance
CLI=/usr/lib/hiddify/HiddifyCli
DATA="$HOME/.local/share/app.hiddify.com"
RUNDIR="$HOME/.local/state/hiddify-instance"

usage() { echo "usage: $0 start tun|proxy|stop|status" >&2; exit 1; }

case "${1:-}" in
    start)
        mode=${2:-tun}
        [ "$mode" = tun ] || [ "$mode" = proxy ] || usage
        cfg_id=$(sqlite3 "$DATA/db.sqlite" "SELECT id FROM profile_entries WHERE active=1 LIMIT 1;")
        [ -n "$cfg_id" ] || { echo "no active Hiddify profile" >&2; exit 1; }
        flag=$([ "$mode" = tun ] && echo --tun || echo --system-proxy)
        mkdir -p "$RUNDIR"
        systemctl --user reset-failed "$UNIT" >/dev/null 2>&1 || true
        systemd-run --user --collect --unit="$UNIT" \
            "$CLI" run -c "$DATA/configs/$cfg_id.json" "$flag" -D "$RUNDIR"
        ;;
    stop)
        # HiddifyCli only arms its SIGTERM handler after its startup +
        # first monitoring pass (~5s, observed) -- stopping earlier kills it
        # before it can revert the system-proxy gsetting/tun route it set up,
        # leaking that state. Wait for its own readiness line first.
        # ponytail: log-line poll with a fixed timeout, not an IPC readiness
        # signal -- fine at this scale, revisit if the delay ever changes.
        if systemctl --user is-active --quiet "$UNIT"; then
            for _ in $(seq 1 40); do
                journalctl --user -u "$UNIT" --since "-10 seconds" --no-pager 2>/dev/null \
                    | grep -q "Waiting for CTRL+C" && break
                sleep 0.2
            done
        fi
        systemctl --user stop "$UNIT" >/dev/null 2>&1 || true
        ;;
    status)
        systemctl --user is-active "$UNIT" 2>/dev/null || true
        ;;
    *)
        usage
        ;;
esac
