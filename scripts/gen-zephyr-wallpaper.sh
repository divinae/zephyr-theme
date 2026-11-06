#!/usr/bin/env bash
# Mute a Plasma wallpaper package (one with contents/images and contents/images_dark) for
# the Zephyr Lauds/Compline themes, into a new package "<name> Zephyr":
#   light (images/):      saturation 0.5 + the Lauds tone curve
#   dark  (images_dark/): saturation 0.5 + a Compline curve with a smaller
#                         shadow lift (the full lift turns this dark image foggy)
# KDE picks images/ or images_dark/ itself by the color scheme's lightness.
#
# Usage: gen-zephyr-wallpaper.sh SOURCE-PACKAGE [OUTPUT-PACKAGE]
#   e.g. gen-zephyr-wallpaper.sh /usr/share/wallpapers/Next ~/.local/share/wallpapers/next-zephyr

set -euo pipefail

[ $# -ge 1 ] || { sed -n '2,12p' "$0"; exit 1; }
SRC=${1%/}
OUT=${2:-$HOME/.local/share/wallpapers/$(basename "$SRC" | tr '[:upper:]' '[:lower:]')-zephyr}

LIGHT="format=rgb24,eq=saturation=0.5,curves=r='0/0.06 0.25/0.22 0.75/0.80 1/0.96':g='0/0.057 0.25/0.215 0.75/0.795 1/0.955':b='0/0.053 0.25/0.21 0.75/0.79 1/0.945'"
DARK="format=rgb24,eq=saturation=0.5,curves=r='0/0.024 0.5/0.49 1/0.941':g='0/0.027 0.5/0.495 1/0.937':b='0/0.031 0.5/0.505 1/0.922'"

command -v ffmpeg >/dev/null || { echo "ffmpeg missing"; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT/contents/images" "$OUT/contents/images_dark"

for f in "$SRC"/contents/images/*; do
    ffmpeg -v error -y -i "$f" -vf "$LIGHT" "$OUT/contents/images/$(basename "$f")"
done
for f in "$SRC"/contents/images_dark/*; do
    ffmpeg -v error -y -i "$f" -vf "$DARK" "$OUT/contents/images_dark/$(basename "$f")"
done

# The name from the source, " Zephyr" after it; its licence too (a muted copy is still its work)
python3 - "$SRC/metadata.json" "$OUT/metadata.json" <<'PY'
import json, sys
try:
    src = json.load(open(sys.argv[1])).get("KPlugin", {})
except (OSError, ValueError):
    src = {}
name = (src.get("Name") or "Wallpaper") + " Zephyr"
out = {"KPlugin": {"Id": name.replace(" ", ""), "Name": name, "Authors": src.get("Authors", [])}}
if src.get("License"):
    out["KPlugin"]["License"] = src["License"]
json.dump(out, open(sys.argv[2], "w"), indent=4, ensure_ascii=False)
PY

echo "built $OUT"
