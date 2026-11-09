#!/usr/bin/env bash
# Sync Konsole/Yakuake profile with the Plasma color scheme. Called as
# `konsole-theme-sync.sh light|dark` by theme-watch.sh (the single portal
# watcher); switches both new windows (kwriteconfig6) and live sessions (D-Bus).

set -u

profile_bg() {
    # $1 = profile name -> echoes "r,g,b" background of its color scheme
    local pfile sfile scheme
    pfile="$HOME/.local/share/konsole/$1.profile"
    scheme=$(kreadconfig6 --file "$pfile" --group Appearance --key ColorScheme 2>/dev/null)
    [ -z "$scheme" ] && return 0
    sfile="$HOME/.local/share/konsole/$scheme.colorscheme"
    kreadconfig6 --file "$sfile" --group Background --key Color 2>/dev/null
}

set_session_profiles() {
    # $1 = service, $2 = profile name. Needs [KonsoleWindow]
    # EnableSecuritySensitiveDBusAPI=true in the app's rc (konsolerc / yakuakerc,
    # read at app start); without it Konsole refuses (AccessDenied) or silently
    # ignores the call. A refusal is logged once per service, not fatal.
    local svc=$1 profile=$2 sess failed=0
    while read -r sess; do
        # Read back: a silently ignored call also returns 0.
        if ! qdbus6 "$svc" "$sess" org.kde.konsole.Session.setProfile "$profile" >/dev/null 2>&1 \
            || [ "$(qdbus6 "$svc" "$sess" org.kde.konsole.Session.profile 2>/dev/null)" != "$profile" ]; then
            failed=$((failed + 1))
        fi
    done < <(qdbus6 "$svc" 2>/dev/null | grep -E '^/Sessions/[0-9]+$')
    [ "$failed" -gt 0 ] && echo "konsole: $svc refused setProfile '$profile' ($failed sessions;" \
        "restart it after enabling EnableSecuritySensitiveDBusAPI)" >&2
    return 0
}

active_scheme() {
    # Active KDE color scheme; the portal only says light/dark, this tells the
    # variant (Zephyr Dark/Light = Breeze schemes, ZephyrCompline/ZephyrLauds).
    kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null
}

apply() {
    local mode=$1 profile yakuake_skin yakuake_bg scheme
    scheme=$(active_scheme)
    if [ "$scheme" = "ZephyrCompline" ] || [ "$scheme" = "ZephyrLauds" ]; then
        profile="Profile - Zephyr ${scheme#Zephyr}"   # Profile - Zephyr Lauds
        yakuake_skin="Zephyr ${scheme#Zephyr}"
    elif [ "$mode" = "dark" ]; then
        # Other schemes: Konsole's plain profiles, Yakuake still a Zephyr skin by light/dark
        profile="Profile - Dark"
        yakuake_skin="Zephyr Compline"
    else
        profile="Profile - Light"
        yakuake_skin="Zephyr Lauds"
    fi
    # Match Yakuake background to the active Konsole profile's color scheme.
    yakuake_bg=$(profile_bg "$profile")

    # Konsole >= 26.08: new sessions pick the light/dark profile pair by the
    # system scheme (SyncProfileWithSystemTheme). Keep the pair on the active
    # variant. Open sessions are switched below over D-Bus, which needs
    # [KonsoleWindow] EnableSecuritySensitiveDBusAPI=true (konsolerc+yakuakerc).
    local light dark rc
    case "$scheme" in
        ZephyrCompline|ZephyrLauds) light="Profile - Zephyr Lauds"; dark="Profile - Zephyr Compline" ;;
        *)              light="Profile - Light"; dark="Profile - Dark" ;;
    esac
    for rc in konsolerc yakuakerc; do
        kwriteconfig6 --file "$rc" --group LightDarkTheme --key LightThemeProfile "$light"
        kwriteconfig6 --file "$rc" --group LightDarkTheme --key DarkThemeProfile "$dark"
    done

    # DefaultProfile: fallback for when SyncProfileWithSystemTheme is off.
    # Konsole's window (menu/tab bar) colors follow the system scheme because
    # [UiSettings] ColorScheme is left unset.
    kwriteconfig6 --file konsolerc --group "Desktop Entry" \
        --key DefaultProfile "${profile}.profile"
    kwriteconfig6 --file yakuakerc --group "Desktop Entry" \
        --key DefaultProfile "${profile}.profile"
    # Yakuake skin (applies on next Yakuake start; no live-reload D-Bus exists).
    # Only a skin that's installed: Yakuake silently falls back to its default for a
    # missing one, so say so in the service's log instead and keep the current skin.
    if [ -d "${XDG_DATA_HOME:-$HOME/.local/share}/yakuake/kns_skins/$yakuake_skin" ]; then
        kwriteconfig6 --file yakuakerc --group Appearance \
            --key Skin "$yakuake_skin"
        kwriteconfig6 --file yakuakerc --group Appearance \
            --key SkinInstalledWithKns true
    else
        echo "yakuake: skin '$yakuake_skin' isn't installed; run install.sh from the zephyr-theme checkout" >&2
    fi
    [ -n "$yakuake_bg" ] && kwriteconfig6 --file yakuakerc --group Appearance \
        --key BackgroundColor "$yakuake_bg"

    # Live Konsole windows.
    qdbus6 2>/dev/null | grep -o 'org.kde.konsole-[0-9]*' | while read -r svc; do
        set_session_profiles "$svc" "$profile"
    done

    # Live Yakuake (embedded Konsole sessions).
    if qdbus6 2>/dev/null | grep -q '^ *org.kde.yakuake$'; then
        set_session_profiles org.kde.yakuake "$profile"
    fi
}

case "${1:-}" in
    light|dark) apply "$1" ;;
    *) echo "usage: $0 [light|dark]"; exit 1 ;;
esac
