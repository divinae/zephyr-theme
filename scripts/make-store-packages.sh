#!/usr/bin/env bash
# The KDE Store's files, one archive per product, into dist/ (see docs/kde-store.md):
# the global themes, the Plasma styles, the colour schemes, Konsole's and Yakuake's themes.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO/dist"
rm -rf "$OUT"; mkdir -p "$OUT"
pack() { local name=$1 dir=$2; shift 2; (cd "$dir" && tar -czf "$OUT/$name" --owner=0 --group=0 "$@"); echo "  $name"; }
cd "$REPO"
pack zephyr-lauds-global-theme.tar.gz plasma/look-and-feel zephyr-lauds
pack zephyr-compline-global-theme.tar.gz plasma/look-and-feel zephyr-compline
pack zephyr-light-plasma-style.tar.gz plasma/desktoptheme zephyr-light
pack zephyr-dark-plasma-style.tar.gz plasma/desktoptheme zephyr-dark
pack ZephyrLauds.colors.tar.gz plasma/color-schemes ZephyrLauds.colors
pack ZephyrCompline.colors.tar.gz plasma/color-schemes ZephyrCompline.colors
pack zephyr-konsole.tar.gz plasma/konsole "Zephyr Lauds.colorscheme" "Zephyr Compline.colorscheme"
pack zephyr-yakuake.tar.gz yakuake/kns_skins "Zephyr Lauds" "Zephyr Compline"
echo "in $OUT"
