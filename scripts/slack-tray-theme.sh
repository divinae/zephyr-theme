#!/usr/bin/env bash
# Theme Slack's (flatpak) system-tray icon and keep it in sync with the Plasma
# light/dark color scheme.
#
# Why: on Linux, Slack does NOT use the .ico files nor the system icon theme for
# its tray icon. setTrayIcon() in dist/main.bundle.cjs picks a base64 PNG
# data-URL embedded in app.asar (Slack >= 4.5x: object keys rest/unread/highlight;
# older builds: variables FP=rest, ZP=unread, PP=highlight).
# So the only way to retheme it is to rewrite those three data-URLs inside the
# asar and repack it. Slack loads the icon once at startup, so the new icon
# shows on Slack's next launch. We deliberately do NOT restart Slack (a theme
# switch at sunset would drop a huddle/call); the asar is swapped atomically
# (rename), so a running Slack keeps reading its old, still-open file.
#
# We pre-build a "light" and a "dark" variant of app.asar (mono glyphs rendered
# from the Colloid icon theme) into a cache, then just copy the matching variant
# over the live asar on theme change. A flatpak update restores the stock asar;
# `apply` detects the unknown asar and rebuilds the variants automatically.
#
# Requires Slack installed as a --user flatpak (writable asar, no sudo).
#
# Usage:
#   slack-tray-theme.sh [light|dark]   apply a variant now (default: light)
#   slack-tray-theme.sh build          (re)build cached variants from stock asar
#   slack-tray-theme.sh restore        restore the stock asar
#
# Theme changes are driven by theme-watch.sh, which calls this as
# `slack-tray-theme.sh light|dark`.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/slack-tray-theme"
ASAR_DIR="$REPO/scripts/asar-tool"
ASAR_BIN="$ASAR_DIR/node_modules/.bin/asar"

# tray state -> (Colloid svg basename, asar variable)
declare -A SVG=( [rest]=slack-indicator [unread]=slack-indicator-unread [highlight]=slack-indicator-highlight )
declare -A VAR=( [rest]=FP [unread]=ZP [highlight]=PP )

# Pinned @electron/asar (no runtime npx fetch). Installs once if missing.
ensure_asar() {
    if [ ! -x "$ASAR_BIN" ]; then
        echo "Installing pinned @electron/asar (one-time) ..."
        npm install --prefix "$ASAR_DIR" --no-audit --no-fund >/dev/null 2>&1
    fi
}
asar_run() { ensure_asar; "$ASAR_BIN" "$@"; }

find_asar() {
    local base f
    for base in "$HOME/.local/share/flatpak" /var/lib/flatpak; do
        f=$(find "$base/app/com.slack.Slack" -name app.asar 2>/dev/null | grep -v '\.orig$' | head -1)
        [ -n "$f" ] && { echo "$f"; return 0; }
    done
    return 1
}

sha() { sha256sum "$1" 2>/dev/null | cut -d' ' -f1; }

slack_running() { pgrep -f 'com\.slack\.Slack' >/dev/null 2>&1; }

# Atomic replace: copy next to the target, then rename. Overwriting in place
# would change the file under a running Slack (Electron keeps app.asar open).
install_asar() {
    local src=$1 dst=$2
    cp "$src" "$dst.new.$$" && mv -f "$dst.new.$$" "$dst"
}

pending_note() {
    slack_running && echo "Slack is running: the new tray icon shows after its next start."
    return 0
}

# Build one variant: extract stock asar, swap the 3 data-URLs, repack.
# Explicit "|| return 1": build_variant runs in an `if` (build_from), where
# set -e is suspended.
# $1=mode(light|dark)  $2=src stock asar  $3=output asar
build_variant() {
    local mode=$1 src=$2 out=$3 colloid tmp bundle state svgfile png b64 var
    case "$mode" in
        light) colloid="$HOME/.local/share/icons/Colloid-Light/status/22" ;;
        dark)  colloid="$HOME/.local/share/icons/Colloid-Dark/status/22"  ;;
    esac
    tmp=$(mktemp -d)
    asar_run extract "$src" "$tmp/x" || { rm -rf "$tmp"; return 1; }
    bundle="$tmp/x/dist/main.bundle.cjs"
    [ -f "$bundle" ] || { echo "main.bundle.cjs not found"; rm -rf "$tmp"; return 1; }
    for state in rest unread highlight; do
        png="$tmp/$state.png"; svgfile="$colloid/${SVG[$state]}.svg"
        if [ -f "$svgfile" ] && command -v rsvg-convert >/dev/null; then
            rsvg-convert -w 22 -h 22 "$svgfile" -o "$png" || { rm -rf "$tmp"; return 1; }
        else
            cp "$REPO/ikonki/slack/slack-tray-$state.png" "$png" || { rm -rf "$tmp"; return 1; }  # light-only fallback
        fi
        b64=$(base64 -w0 "$png"); var="${VAR[$state]}"
        node -e '
            const fs=require("fs");
            const [file,state,v,b64]=process.argv.slice(1);
            let s=fs.readFileSync(file,"utf8");
            const url="[\"\x27]data:image/png;base64,[A-Za-z0-9+/=]*[\"\x27]";
            // Slack >= 4.5x: one object {highlight:"data:..",rest:"..",unread:".."}
            // keyed by tray state. Older: minified vars FP/ZP/PP=".." (fallback).
            const byKey=new RegExp("([{,]\\s*"+state+"\\s*:\\s*)"+url,"g");
            const byVar=new RegExp("(\\b"+v+"=)"+url,"g");
            const hits=(re)=>(s.match(re)||[]).length;
            const re=hits(byKey)===1?byKey:(hits(byVar)===1?byVar:null);
            if(!re){console.error("tray icon pattern not found (or ambiguous): "+state+"/"+v);process.exit(2);}
            s=s.replace(re,(m,pre)=>pre+"\"data:image/png;base64,"+b64+"\"");
            fs.writeFileSync(file,s);
        ' "$bundle" "$state" "$var" "$b64" || { rm -rf "$tmp"; return 1; }
    done
    asar_run pack "$tmp/x" "$out" --unpack "**/*.node" || { rm -rf "$tmp"; return 1; }
    rm -rf "$tmp"
}

# (Re)build both cached variants from a given stock asar ($1).
# NOTE: extraction must read from the asar in its original location, because the
# companion `app.asar.unpacked/` (native .node modules etc.) lives next to it.
# We only ever overwrite the live .asar file; the live .unpacked sibling stays
# intact and matches the repacked variants (packed with --unpack "**/*.node").
#
# Atomic: both variants are built into a temp dir and only then moved into the
# cache, together with built_from.sha256 (the stock they belong to). A failed
# build (e.g. a Slack update renamed the bundle variables) leaves the cache
# untouched, and stale variants are dropped so apply can never install a
# variant built from a different Slack version (that broke Slack once).
build_from() {
    local stock=$1 work
    mkdir -p "$CACHE"
    work=$(mktemp -d)
    echo "Building light variant ..."
    if ! build_variant light "$stock" "$work/light.asar" \
        || { echo "Building dark variant ..."; ! build_variant dark "$stock" "$work/dark.asar"; }; then
        rm -rf "$work" "$CACHE"/light.asar* "$CACHE"/dark.asar* "$CACHE/built_from.sha256"
        return 1
    fi
    cp "$stock" "$CACHE/stock.asar"            # backup blob (for restore)
    sha "$stock" > "$CACHE/stock.sha256"
    rm -rf "$CACHE"/light.asar* "$CACHE"/dark.asar*
    mv "$work/light.asar" "$work/dark.asar" "$CACHE/"
    sha "$stock" > "$CACHE/built_from.sha256"
    rm -rf "$work"
    echo "Variants cached in $CACHE."
}

build() {
    local asar; asar=$(find_asar) || { echo "Slack app.asar not found"; exit 1; }
    build_from "$asar"
}

apply() {
    local mode=$1 asar cur lsha dsha need
    asar=$(find_asar) || { echo "Slack app.asar not found"; exit 1; }
    cur=$(sha "$asar")

    # This exact Slack build already failed to patch: don't retry on every
    # theme switch (a Slack update changes the sha and retries automatically).
    if [ "$cur" = "$(cat "$CACHE/unsupported.sha256" 2>/dev/null)" ]; then
        echo "Tray theming unsupported for this Slack version (cached), leaving stock."
        return 0
    fi

    # Rebuild variants if missing, or if the live asar is unknown to us
    # (fresh install / post-update stock -> rebuild from it).
    # Variants are only valid for the stock they were built from.
    need=0
    [ -f "$CACHE/light.asar" ] && [ -f "$CACHE/dark.asar" ] || need=1
    [ "$(cat "$CACHE/built_from.sha256" 2>/dev/null)" = "$(cat "$CACHE/stock.sha256" 2>/dev/null)" ] || need=1
    if [ "$need" = 0 ] \
        && [ "$cur" != "$(sha "$CACHE/light.asar")" ] \
        && [ "$cur" != "$(sha "$CACHE/dark.asar")" ] \
        && [ "$cur" != "$(cat "$CACHE/stock.sha256" 2>/dev/null)" ]; then
        need=1
    fi
    if [ "$need" = 1 ]; then
        # Only rebuild from a live asar we know is stock: the cached stock, or
        # an unknown one (fresh install / Slack update).
        echo "Rebuilding variants from current asar ..."
        # Keep a real stock backup next to the asar (refresh it on update).
        case "$cur" in
            "$(sha "$CACHE/light.asar")"|"$(sha "$CACHE/dark.asar")") ;;
            *) cp "$asar" "$asar.orig" ;;
        esac
        if ! build_from "$asar"; then
            echo "Tray theming unsupported for this Slack version, leaving stock asar."
            echo "$cur" > "$CACHE/unsupported.sha256"
            return 0
        fi
        cur=$(sha "$asar")
    fi

    dsha=$(sha "$CACHE/$mode.asar")
    if [ "$cur" = "$dsha" ]; then
        echo "Already '$mode'."
        return 0
    fi
    install_asar "$CACHE/$mode.asar" "$asar"
    echo "Applied '$mode'."
    pending_note
}

restore() {
    local asar; asar=$(find_asar) || { echo "Slack app.asar not found"; exit 1; }
    if [ -f "$asar.orig" ]; then install_asar "$asar.orig" "$asar"
    elif [ -f "$CACHE/stock.asar" ]; then install_asar "$CACHE/stock.asar" "$asar"
    else echo "no stock backup found"; exit 1; fi
    echo "Restored stock asar."
    pending_note
}

case "${1:-light}" in
    light|dark) apply "$1" ;;
    build)      build ;;
    restore)    restore ;;
    *) echo "usage: $0 [light|dark|build|restore]"; exit 1 ;;
esac
