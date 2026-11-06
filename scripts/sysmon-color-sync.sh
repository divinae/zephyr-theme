#!/usr/bin/env bash
# Sync the System Monitor Sensor widget bar color with the Plasma color scheme.
#
# Why: org.kde.plasma.systemmonitor (horizontalbars face) stores bar colors as
# fixed RGB in config group /SensorColors. It has NO "follow theme" option, so
# the CPU-total and RAM bars stay one color and go invisible (dark-on-dark) when
# the scheme flips. We repaint just those two foreground-tracked sensors to the
# active scheme's ForegroundNormal on each theme change.
#
# plasmashell owns plasma-org.kde.plasma.desktop-appletsrc and clobbers external
# kwriteconfig6 writes, so we drive the change through the Plasma scripting API
# (the same one the look-and-feel layout.js uses) over D-Bus. This applies live,
# no plasmashell restart.
#
# Usage: sysmon-color-sync.sh [light|dark]   (default: light)

set -u

# Sensors whose color should equal the panel foreground.
SENSORS=( "cpu/all/usage" "memory/physical/usedPercent" )

scheme_for() {
    # $1 = light|dark -> color-scheme name: the active one, whatever it is.
    # Only if that can't be read, fall back to Breeze for the mode.
    local active
    active=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null)
    if [ -n "$active" ]; then echo "$active"; return; fi
    [ "$1" = "dark" ] && echo "BreezeDark" || echo "BreezeLight"
}

foreground() {
    # $1 = scheme name -> "r,g,b" of [Colors:View] ForegroundNormal
    local name=$1 f
    # User schemes first: a local copy overrides the system one, as in Plasma.
    for base in "$HOME/.local/share/color-schemes" /usr/share/color-schemes; do
        f="$base/$name.colors"
        [ -f "$f" ] || continue
        kreadconfig6 --file "$f" --group "Colors:View" --key ForegroundNormal 2>/dev/null
        return 0
    done
}

apply() {
    local mode=$1 fg js sensor
    fg=$(foreground "$(scheme_for "$mode")")
    [ -z "$fg" ] && { echo "no foreground color for $mode"; return 1; }

    js='var fg="'"$fg"'";'
    js+='var paint=function(ws){for(var i=0;i<ws.length;i++){var w=ws[i];'
    js+='if(w.type=="org.kde.plasma.systemmonitor"){w.currentConfigGroup=["SensorColors"];'
    for sensor in "${SENSORS[@]}"; do
        js+='w.writeConfig("'"$sensor"'",fg);'
    done
    js+='w.reloadConfig();}}};'
    js+='var ps=panels();for(var p=0;p<ps.length;p++)paint(ps[p].widgets());'
    js+='var ds=desktops();for(var d=0;d<ds.length;d++)paint(ds[d].widgets());'

    if ! qdbus6 org.kde.plasmashell /PlasmaShell \
        org.kde.PlasmaShell.evaluateScript "$js" >/dev/null 2>&1; then
        echo "sysmon: plasmashell not reachable, colors not applied ($mode)" >&2
        return 1
    fi
    echo "sysmon sensors -> $fg ($mode)"
}

case "${1:-light}" in
    light|dark) apply "$1" ;;
    *) echo "usage: $0 [light|dark]"; exit 1 ;;
esac
