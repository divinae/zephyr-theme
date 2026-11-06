#!/usr/bin/env python3
"""Generate a muted (desaturated) variant of a Colloid icon theme.

Why: the Zephyr Compline/Lauds theme variant is near-monochrome; stock Colloid app
icons are loud. This copies the full-colour `scalable` icons of a source theme
and scales every hex colour's HLS saturation by a factor (same idea as the
muted video wallpapers). `ColorScheme-*` stylesheet classes are untouched, so
folders keep following the colour scheme's Highlight. Everything else
(symbolic / small action icons) is inherited from the source theme.

Output is generated into ~/.local/share/icons/<name> and is NOT committed.

Usage:
  python3 -I scripts/gen-muted-icons.py --src Colloid-Light --name Colloid-Zephyr-Lauds
  python3 -I scripts/gen-muted-icons.py --src Colloid-Dark  --name Colloid-Zephyr-Compline --saturation 0.5
"""
import argparse
import colorsys
import os
import re
import shutil
import subprocess
import sys

HEX = re.compile(r"#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b")


def mute(match, factor):
    h = match.group(1)
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    hue, light, sat = colorsys.rgb_to_hls(r, g, b)
    r, g, b = colorsys.hls_to_rgb(hue, light, sat * factor)
    return "#%02x%02x%02x" % tuple(round(c * 255) for c in (r, g, b))


def materialize_external_links(out):
    """Replace links that leave the new theme (e.g. Colloid-Dark/apps/scalable
    -> ../../Colloid-Light/apps/scalable) or dangle, with real copies, so the
    copied icons are ours to recolour. Links staying inside are kept."""
    root = os.path.realpath(out)
    changed = True
    while changed:
        changed = False
        for dirpath, dirs, files in os.walk(out):
            for f in dirs + files:
                p = os.path.join(dirpath, f)
                if not os.path.islink(p):
                    continue
                real = os.path.realpath(p)
                if os.path.exists(p) and (real + os.sep).startswith(root + os.sep):
                    continue
                os.unlink(p)
                if os.path.isdir(real):
                    shutil.copytree(real, p, symlinks=True)
                    changed = True
                elif os.path.exists(real):
                    shutil.copy(real, p)


def recolor_tree(root, factor, skip="symbolic"):
    n = 0
    for dirpath, _, files in os.walk(root):
        if skip in dirpath.split(os.sep):
            continue
        for f in files:
            p = os.path.join(dirpath, f)
            if not f.endswith(".svg") or os.path.islink(p):
                continue
            with open(p, encoding="utf-8", errors="surrogateescape") as fh:
                s = fh.read()
            t = HEX.sub(lambda m: mute(m, factor), s)
            if t != s:
                with open(p, "w", encoding="utf-8", errors="surrogateescape") as fh:
                    fh.write(t)
                n += 1
    return n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True, help="source theme, e.g. Colloid-Light")
    ap.add_argument("--name", required=True, help="output theme, e.g. Colloid-Zephyr-Lauds")
    ap.add_argument("--saturation", type=float, default=0.5, help="saturation factor (0..1)")
    ap.add_argument("--icons-dir", default=os.path.expanduser("~/.local/share/icons"))
    ap.add_argument("--src-dir", help="where the source theme is, if not in --icons-dir (e.g. /usr/share/icons)")
    a = ap.parse_args()

    src = os.path.join(a.src_dir or a.icons_dir, a.src)
    out = os.path.join(a.icons_dir, a.name)
    if not os.path.isfile(os.path.join(src, "index.theme")):
        sys.exit(f"no such theme: {src}")
    if os.path.realpath(out) == os.path.realpath(src):
        sys.exit("refusing to overwrite the source theme")
    if os.path.exists(out):
        shutil.rmtree(out)
    os.makedirs(out)

    # Full copy of the source theme, so icon lookup behaves exactly like the
    # source (a scalable-only theme shadows the small monochrome tray icons in
    # 16/22/24 with big colourful ones). Every size is recoloured (the logout screen uses
    # actions/32); */symbolic/* is skipped, monochrome greys are unaffected anyway.
    for entry in os.listdir(src):
        if entry in ("index.theme", "icon-theme.cache"):
            continue
        sp = os.path.join(src, entry)
        dp = os.path.join(out, entry)
        if os.path.islink(sp) and os.path.dirname(os.path.normpath(
                os.path.join(src, os.readlink(sp)))) == os.path.normpath(src):
            os.symlink(os.readlink(sp), dp)      # e.g. apps@2x -> apps
        elif os.path.isdir(sp):
            shutil.copytree(os.path.realpath(sp), dp, symlinks=True)
    materialize_external_links(out)

    changed = recolor_tree(out, a.saturation)

    with open(os.path.join(src, "index.theme"), encoding="utf-8") as fh:
        idx = fh.read()
    idx = re.sub(r"(?m)^Name=.*$", f"Name={a.name}", idx, count=1)
    idx = re.sub(r"(?m)^Inherits=.*$", f"Inherits={a.src},hicolor,breeze", idx, count=1)
    with open(os.path.join(out, "index.theme"), "w", encoding="utf-8") as fh:
        fh.write(idx)

    if shutil.which("gtk-update-icon-cache"):
        subprocess.run(["gtk-update-icon-cache", "-f", "-q", "-t", out], check=False)
    print(f"{a.name}: {changed} svgs muted (x{a.saturation}) from {a.src} -> {out}")


if __name__ == "__main__":
    main()
