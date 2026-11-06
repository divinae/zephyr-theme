#!/usr/bin/env bash
# Pack the Zephyr Lauds / Zephyr Compline Vivaldi themes into importable zips
# (Vivaldi's theme export format: a zip with settings.json at the root).
#
# Colors mirror plasma/color-schemes/Zephyr{Lauds,Compline}.colors: window bg,
# header (bg-alt) as accent/window, muted-blue selection as highlight.
#
# Import: Vivaldi -> Settings -> Themes -> Import (pick the zip), then
# Theme Schedule -> Use OS theme: light = Zephyr Lauds, dark = Zephyr Compline.
# Edit the .json sources, then re-run this script.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

command -v zip >/dev/null || { echo "zip missing"; exit 1; }

for src in zephyr-lauds.json zephyr-compline.json; do
    name=$(python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1]))["name"])' "$src")
    tmp=$(mktemp -d)
    cp "$src" "$tmp/settings.json"
    rm -f "$name.zip"
    zip -j -q "$name.zip" "$tmp/settings.json"
    rm -rf "$tmp"
    echo "built $name.zip"
done
