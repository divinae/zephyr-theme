#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Jakub Lipiński <lipinski.j@pm.me>
# SPDX-License-Identifier: GPL-3.0-only
#
# Zephyr Lauds (light) and Zephyr Compline (dark) for KDE Plasma 6, into ~/.local:
#
#   ./install.sh               colour schemes, Plasma styles, global themes, Konsole and Yakuake
#                              themes, and the muted Colloid icons (if Colloid is installed)
#   ./install.sh --sync        the same, and the light/dark sync service (Konsole, Yakuake,
#                              System Monitor, Slack's tray icon follow Plasma's scheme)
#   ./install.sh --uninstall   removes all of it again
#
# Nothing here needs root. The sync service runs the scripts from this checkout, so keep it
# where it is (or run --sync again after moving it).

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
UNITS="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

sync=false
uninstall=false
for arg in "$@"; do
    case "$arg" in
        --sync) sync=true ;;
        --uninstall) uninstall=true ;;
        -h|--help) sed -n '5,14p' "$0"; exit 0 ;;
        *) echo "unknown option: $arg" >&2; exit 1 ;;
    esac
done

# What goes where: source in this repo, destination under $DATA
pieces=(
    "plasma/color-schemes/ZephyrLauds.colors:color-schemes/ZephyrLauds.colors"
    "plasma/color-schemes/ZephyrCompline.colors:color-schemes/ZephyrCompline.colors"
    "plasma/desktoptheme/zephyr-light:plasma/desktoptheme/zephyr-light"
    "plasma/desktoptheme/zephyr-dark:plasma/desktoptheme/zephyr-dark"
    "plasma/look-and-feel/zephyr-lauds:plasma/look-and-feel/zephyr-lauds"
    "plasma/look-and-feel/zephyr-compline:plasma/look-and-feel/zephyr-compline"
    "plasma/konsole/Zephyr Lauds.colorscheme:konsole/Zephyr Lauds.colorscheme"
    "plasma/konsole/Zephyr Compline.colorscheme:konsole/Zephyr Compline.colorscheme"
    "plasma/konsole/Profile - Zephyr Lauds.profile:konsole/Profile - Zephyr Lauds.profile"
    "plasma/konsole/Profile - Zephyr Compline.profile:konsole/Profile - Zephyr Compline.profile"
    "yakuake/kns_skins/Zephyr Lauds:yakuake/kns_skins/Zephyr Lauds"
    "yakuake/kns_skins/Zephyr Compline:yakuake/kns_skins/Zephyr Compline"
)
icons=("Colloid-Light:Colloid-Zephyr-Lauds" "Colloid-Dark:Colloid-Zephyr-Compline")

if $uninstall; then
    if systemctl --user list-unit-files zephyr-theme-sync.service >/dev/null 2>&1; then
        systemctl --user disable --now zephyr-theme-sync.service 2>/dev/null || true
    fi
    rm -f "$UNITS/zephyr-theme-sync.service"
    for p in "${pieces[@]}"; do rm -rf "$DATA/${p#*:}"; done
    for i in "${icons[@]}"; do rm -rf "$DATA/icons/${i#*:}"; done
    echo "Zephyr removed. Pick another colour scheme and global theme in System Settings."
    exit 0
fi

for p in "${pieces[@]}"; do
    src="$REPO/${p%%:*}" dst="$DATA/${p#*:}"
    mkdir -p "$(dirname "$dst")"
    rm -rf "$dst"
    cp -r "$src" "$dst"
done
echo "Installed the colour schemes, Plasma styles, global themes, Konsole and Yakuake themes."

# The icons: Colloid, desaturated to sit with the near-monochrome palette
for i in "${icons[@]}"; do
    from=${i%%:*} to=${i#*:} where=""
    for dir in "$DATA/icons" /usr/share/icons; do
        [ -f "$dir/$from/index.theme" ] && { where=$dir; break; }
    done
    if [ -z "$where" ]; then
        echo "No $from icon theme found: install Colloid (https://github.com/vinceliuice/Colloid-icon-theme)"
        echo "  and run ./install.sh again for the $to icons."
        continue
    fi
    python3 -I "$REPO/scripts/gen-muted-icons.py" --src "$from" --name "$to" --src-dir "$where" --icons-dir "$DATA/icons"
done

if $sync; then
    mkdir -p "$UNITS"
    sed "s|@REPO@|$REPO|g" "$REPO/systemd/user/zephyr-theme-sync.service.in" > "$UNITS/zephyr-theme-sync.service"
    systemctl --user daemon-reload
    systemctl --user enable --now zephyr-theme-sync.service
    echo "The light/dark sync runs (zephyr-theme-sync.service), from $REPO/scripts."
fi

echo "Now pick Zephyr Lauds or Zephyr Compline in System Settings > Colors & Themes > Global Theme."
