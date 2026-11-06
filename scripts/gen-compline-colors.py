#!/usr/bin/env python3
"""Generate the Zephyr Compline (dark) / Zephyr Lauds (light) KDE color schemes.

Derived from the Compline/Lauds palette, with own tweaks (buttons, header,
selection, neutral), hence the own names.

Palette: https://complinetheme.com/palette. Edit the palette / role mapping
here, not the .colors files, then regenerate:

  python3 -I scripts/gen-compline-colors.py plasma/color-schemes

Re-apply a scheme to see changes live (also regenerates GTK colors):
  plasma-apply-colorscheme BreezeLightLowContrast && plasma-apply-colorscheme ZephyrLauds
"""
import sys
def rgb(h): h=h.lstrip('#'); return ','.join(str(int(h[i:i+2],16)) for i in (0,2,4))

P = {
 'compline': dict(bg='#1a1d21',bgalt='#22262b',hdr='#22262b',btn='#282c34',btnalt='#3d424a',b0='#0f1114',b1='#171a1e',b2='#1f2228',b3='#282c34',b4='#3d424a',b7='#8b919a',
   fg='#f0efeb',inact='#8b919a',red='#cdacac',yellow='#c9c5ba',green='#b8c4b8',blue='#91b7ca',cyan='#a5c4d4',dcyan='#98a4ac'),
 # Accent (blue) = Breeze's hue 200deg at ~half saturation and Breeze-like
 # lightness (user: like Breeze, less saturated; white selection text like
 # Breeze, ~2.8:1 accepted). Links: same hue, darker for readability. Lauds backgrounds/neutrals = Breeze Light (user preferred them over the warm
 # Lauds beige); text, accents and selection stay from the Lauds palette.
 'lauds': dict(bg='#eff0f1',bgalt='#e3e5e7',hdr='#dee0e2',btn='#fcfcfc',btnalt='#d3e4ed',b0='#ffffff',b1='#f7f7f7',b2='#e3e5e7',b3='#dee0e2',b4='#bdc3c7',b7='#707d8a',b8='#2a2e32',
   fg='#1a1d21',inact='#707d8a',red='#8b6666',yellow='#857f72',green='#5a6b5a',blue='#599dc0',cyan='#30647e',dcyan='#546470'),
}
C, L = P['compline'], P['lauds']

# Text on the selection (blue) background: palette hues pushed light (Lauds,
# dark-blue selection) or dark (Compline, light-blue selection) for >= 4.5:1.
SEL = {
 'lauds': dict(ForegroundNormal='#ffffff', ForegroundActive='#ffffff', ForegroundInactive='#eef2f5',
     ForegroundLink='#e6ecf0', ForegroundVisited='#dde3e7', ForegroundNegative='#f3dede',
     ForegroundNeutral='#eeeae0', ForegroundPositive='#e1e9e1'),
 'compline': dict(ForegroundNormal='#1a1d21', ForegroundActive='#1a1d21', ForegroundInactive='#282c34',
     ForegroundLink='#1f2b36', ForegroundVisited='#27313a', ForegroundNegative='#3d2525',
     ForegroundNeutral='#332e22', ForegroundPositive='#243024'),
}

def fgset(p, fg=None, inact=None, active=None):
    return dict(ForegroundNormal=fg or p['fg'], ForegroundInactive=inact or p['inact'],
        ForegroundActive=active or p['blue'], ForegroundLink=p['cyan'], ForegroundVisited=p['dcyan'],
        ForegroundNegative=p['red'], ForegroundNeutral=p['yellow'], ForegroundPositive=p['green'],
        DecorationFocus=p['blue'], DecorationHover=p['cyan'])

def scheme(name):
    p = P[name.lower()]
    ident, disp = "Zephyr" + name, "Zephyr " + name   # e.g. ZephyrLauds / Zephyr Lauds
    other = L if p is C else C          # selection uses the opposite palette's accents (contrast on blue)
    comp = C                            # complementary is always dark
    comp_bg = C['b0'] if p is C else L['b8']
    groups = {
     'Colors:Window':  dict(BackgroundNormal=p['bg'], BackgroundAlternate=p['bgalt'], **fgset(p)),
     'Colors:View':    dict(BackgroundNormal=p['b1'] if p is C else p['b0'], BackgroundAlternate=p['b2'] if p is C else p['b1'], **fgset(p)),
     # Buttons: raised = lighter than the window in Lauds (as in Breeze Light);
     # btnalt is a light accent tint like Breeze's.
     'Colors:Button':  dict(BackgroundNormal=p['btn'], BackgroundAlternate=p['btnalt'], **fgset(p)),
     # Header (title bar + toolbar) = the palette's bg-alt, set off from the window.
     'Colors:Header':  dict(BackgroundNormal=p['hdr'], BackgroundAlternate=p['bg'], **fgset(p)),
     'Colors:Header][Inactive': dict(BackgroundNormal=p['bg'], BackgroundAlternate=p['hdr'], **fgset(p)),
     'Colors:Tooltip': dict(BackgroundNormal=p['b2'] if p is C else p['b1'], BackgroundAlternate=p['bg'], **fgset(p)),
     'Colors:Complementary': dict(BackgroundNormal=comp_bg, BackgroundAlternate=C['b3'], **fgset(comp)),
     'Colors:Selection': dict(BackgroundNormal=p['blue'], BackgroundAlternate=p['dcyan'],
        **SEL[name.lower()], DecorationFocus=p['blue'], DecorationHover=p['cyan']),
    }
    out = [f"# {disp} — KDE color scheme derived from the Compline palette (https://complinetheme.com)\n"]
    out.append("[ColorEffects:Disabled]\nColor=56,56,56\nColorAmount=0\nColorEffect=0\nContrastAmount=0.65\nContrastEffect=1\nIntensityAmount=0.1\nIntensityEffect=2\n")
    out.append("[ColorEffects:Inactive]\nChangeSelectionColor=true\nColor=112,111,110\nColorAmount=0.025\nColorEffect=2\nContrastAmount=0.1\nContrastEffect=2\nEnable=false\nIntensityAmount=0\nIntensityEffect=0\n")
    for g, kv in groups.items():
        out.append(f"[{g}]\n" + ''.join(f"{k}={rgb(v)}\n" for k, v in sorted(kv.items())))
    out.append(f"[General]\nColorScheme={ident}\nName={disp}\nshadeSortColumn=true\n")
    out.append("[KDE]\nContrast=1\ncontrast=4\nframeContrast=0.1\n")
    out.append("[WM]\n" + ''.join(f"{k}={rgb(v)}\n" for k, v in [
        ('activeBackground', p['hdr']), ('activeBlend', p['hdr']), ('activeForeground', p['fg']),
        ('inactiveBackground', p['bg']), ('inactiveBlend', p['bg']), ('inactiveForeground', p['inact'])]))
    return '\n'.join(out)

outdir = sys.argv[1]
for n in ('Compline', 'Lauds'):  # palette keys; files are Zephyr<n>.colors
    open(f"{outdir}/Zephyr{n}.colors", 'w').write(scheme(n))
