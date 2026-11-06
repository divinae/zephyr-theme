#!/usr/bin/env bash
# Take Global Theme preview screenshots for the zephyr-compline/zephyr-lauds look-and-feel.
#
# Switches to each theme, screenshots the current monitor with spectacle, and
# writes contents/previews/{fullscreenpreview.jpg,preview.png}. Restores the
# Global Theme that was active before. theme-sync.service is stopped meanwhile
# so the temporary dark/light flip doesn't swap Slack's icon or retheme Konsole.
#
# Run it with a clean desktop: whatever is on screen ends up in the repo.
#
# Usage: make-lnf-previews.sh [theme...]   (default: zephyr-compline zephyr-lauds)

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LNF="$REPO/plasma/look-and-feel"
DELAY=${DELAY:-4}
THEMES=("$@")
[ ${#THEMES[@]} -eq 0 ] && THEMES=(zephyr-compline zephyr-lauds)

command -v spectacle >/dev/null || { echo "spectacle missing"; exit 1; }
command -v magick >/dev/null || { echo "imagemagick (magick) missing"; exit 1; }

orig=$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage)
tmp=$(mktemp -d)
restore() {
    plasma-apply-lookandfeel -a "$orig" >/dev/null 2>&1 || true
    systemctl --user start theme-sync.service || true
    rm -rf "$tmp"
    echo "restored $orig"
}
trap restore EXIT

for i in 5 4 3 2 1; do echo "screenshots in $i s ... (clean your desktop)"; sleep 1; done
systemctl --user stop theme-sync.service || true

for t in "${THEMES[@]}"; do
    [ -d "$LNF/$t" ] || { echo "no such theme: $t"; continue; }
    plasma-apply-lookandfeel -a "$t" >/dev/null
    sleep "$DELAY"   # let the panel, wallpaper and windows repaint
    spectacle -b -n -m -o "$tmp/$t.png"
    for _ in $(seq 20); do [ -s "$tmp/$t.png" ] && break; sleep 0.5; done
    out="$LNF/$t/contents/previews"
    magick "$tmp/$t.png" -resize '2560x>' -quality 90 "$out/fullscreenpreview.jpg"
    magick "$tmp/$t.png" -resize '512x320^' -gravity center -extent 512x320 "$out/preview.png"
    echo "$t -> $out"
done
