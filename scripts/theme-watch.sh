#!/usr/bin/env bash
# Single Plasma color-scheme watcher. Owns the ONE gdbus monitor loop and fans
# the light/dark mode out to per-app sync modules. Replaces the per-app watchers
# (konsole-theme-sync.service + slack-tray-sync.service), so only one process
# listens on the freedesktop appearance portal.
#
# Add a module: add its script name to MODULES; it is called as `<script> <mode>`.

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$REPO/scripts"
PORTAL_DEST=org.freedesktop.portal.Desktop
PORTAL_PATH=/org/freedesktop/portal/desktop

MODULES=(
    konsole-theme-sync.sh
    slack-tray-theme.sh
    sysmon-color-sync.sh
)

read_scheme() {
    # 0 = no preference, 1 = dark, 2 = light
    qdbus6 "$PORTAL_DEST" "$PORTAL_PATH" \
        org.freedesktop.portal.Settings.Read \
        org.freedesktop.appearance color-scheme 2>/dev/null
}
mode_for() { [ "${1:-}" = "1" ] && echo dark || echo light; }

dispatch() {
    # $1 = light|dark. Modules touch disjoint subsystems, so run them concurrently
    # (latency = slowest module, not the sum); guard each so one failure can't kill
    # the watcher. wait blocks until all finish, so a second event can't overlap
    # the first (no two concurrent asar swaps).
    local mode=$1 m
    for m in "${MODULES[@]}"; do
        { "$SCRIPTS/$m" "$mode" || echo "module failed: $m ($mode)" >&2; } &
    done
    wait
}

read_kde_scheme() {
    # Active KDE color scheme name (e.g. BreezeDark, ZephyrCompline). Tells the theme
    # *variant*, which the light/dark color-scheme value alone does not.
    qdbus6 "$PORTAL_DEST" "$PORTAL_PATH" \
        org.freedesktop.portal.Settings.Read \
        org.kde.kdeglobals.General ColorScheme 2>/dev/null
}

# Dispatch only when (mode, scheme) actually changed: a Global Theme switch
# fires both color-scheme and ColorScheme signals, and a variant switch with
# the same mode (Zephyr Dark -> Zephyr Compline) fires only ColorScheme.
last=""
sync_now() {
    local mode key
    mode=$(mode_for "$(read_scheme)")
    key="$mode:$(read_kde_scheme)"
    [ "$key" = "$last" ] && return
    last=$key
    dispatch "$mode"
}

# Initial sync at startup.
sync_now

# Single watch loop over the portal's SettingChanged signals.
stdbuf -oL gdbus monitor --session --dest "$PORTAL_DEST" 2>/dev/null \
    | grep --line-buffered -E "color-scheme|'ColorScheme'" \
    | while read -r _; do
        sync_now
    done
