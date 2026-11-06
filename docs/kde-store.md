# KDE Store listing

The store takes each kind of theme as its own product, so Zephyr is eight uploads in five
categories. `scripts/make-store-packages.sh` builds their files into `dist/`. Each product links
the others and this repository.

## Before uploading

- **Credit on every page:** the palette is Compline by Joshua Blais (GPL-3.0), and the icons are
  Colloid by Vince Liuice. On the Yakuake skins' page: recoloured from Slate by TheBigWazz.
- **Screenshots:** the global themes' previews
  (`plasma/look-and-feel/zephyr-*/contents/previews/fullscreenpreview.jpg`) for all of them. For the
  Konsole and Yakuake pages, a screenshot of each.
- **License:** GPL-3.0 for all, except the Plasma styles: LGPL-2.1+ (Breeze's shapes).
- **Donation link:** https://ko-fi.com/divinae4535
- **Source:** https://github.com/divinae/zephyr-theme

## The products

| Product | Store category | File (`dist/`) |
| --- | --- | --- |
| Zephyr Lauds | Plasma 6 Global Themes | `zephyr-lauds-global-theme.tar.gz` |
| Zephyr Compline | Plasma 6 Global Themes | `zephyr-compline-global-theme.tar.gz` |
| Zephyr Light | Plasma 6 Themes (Plasma styles) | `zephyr-light-plasma-style.tar.gz` |
| Zephyr Dark | Plasma 6 Themes (Plasma styles) | `zephyr-dark-plasma-style.tar.gz` |
| Zephyr Lauds | Plasma Color Schemes | `ZephyrLauds.colors.tar.gz` |
| Zephyr Compline | Plasma Color Schemes | `ZephyrCompline.colors.tar.gz` |
| Zephyr Lauds and Compline | Konsole Color Schemes | `zephyr-konsole.tar.gz` |
| Zephyr Lauds and Compline | Yakuake Skins | `zephyr-yakuake.tar.gz` |

The global themes need the colour scheme, the Plasma style and the icons. On the store, the colour
scheme and the Plasma style install with "Get New…" from their own pages. The icons only come from
the repository's `install.sh` (they're generated from Colloid), so the global themes' pages point to
it.

## Text

**Tags**

    zephyr, compline, lauds, light, dark, minimal, calm, monochrome, translucent, plasma6

**Summary (one line)**

    A calm, near-monochrome desktop: Zephyr Lauds by day, Zephyr Compline by night, from the Compline palette.

**Description: the global themes** (each line its own paragraph)

```
A calm, near-monochrome desktop, light by day and dark by night: Zephyr Lauds (light) and Zephyr Compline (dark), from the Compline palette by Joshua Blais.

It brings the colour scheme, a translucent Plasma style (Zephyr Light / Zephyr Dark), muted Colloid icons, Breeze widgets and window frames. Its desktop layout (a floating panel on the left, a dock at the bottom) is the author's, and Plasma asks before using it.

For everything at once, including the icons and the light/dark sync for Konsole, Yakuake, System Monitor and Slack: https://github.com/divinae/zephyr-theme (./install.sh).

Switch by the time of day: System Settings > Global Theme > Switch automatically, Lauds for day and Compline for night.

Palette: Compline by Joshua Blais (GPL-3.0). Icons: Colloid by Vince Liuice.
```

**Description: the colour schemes, Plasma styles, Konsole and Yakuake** (adapt the first line)

```
Zephyr Lauds (light) and Zephyr Compline (dark): a calm, near-monochrome palette from Compline by Joshua Blais, for Plasma 6.

Part of the Zephyr theme, with a global theme, a Plasma style, muted icons and terminal themes: https://github.com/divinae/zephyr-theme
```
