# Zephyr: notes for AI agents

Two KDE Plasma 6 themes from the Compline palette (Joshua Blais): **Zephyr Lauds** (light) and
**Zephyr Compline** (dark). The repo has the colour schemes, translucent Plasma styles, global themes,
Konsole and Yakuake themes, a generator for muted Colloid icons, Vivaldi and Slack themes, and a
light/dark sync service that keeps apps Plasma can't reach in step. Published on GitHub as
`divinae/zephyr-theme` (GPL-3.0) and on the KDE Store as eight separate products (see
`docs/kde-store.md`). Owner: Jakub Lipiński (`divinae`). Push to `origin`, branch `main`, and commit
straight to `main` (it's the owner's repo, so no feature branches).

## Layout

- `plasma/color-schemes/Zephyr{Lauds,Compline}.colors`: **generated** by `scripts/gen-compline-colors.py`.
- `plasma/desktoptheme/zephyr-{light,dark}/`: the Plasma styles ("Zephyr Light/Dark"), Breeze's shapes, LGPL.
- `plasma/look-and-feel/zephyr-{lauds,compline}/`: the global themes. `contents/defaults` sets the
  scheme, `Colloid-Zephyr-*` icons, Breeze widgets/frames and the Plasma style.
  `contents/layouts/org.kde.plasma.desktop-layout.js` is the owner's panel layout (a left panel and
  a bottom dock). `contents/previews/` holds screenshots made by `make-lnf-previews.sh`.
- `plasma/konsole/`: `Zephyr {Lauds,Compline}.colorscheme` and `Profile - Zephyr {Lauds,Compline}.profile`
  (`Command=/bin/zsh`, font Maple Mono NF).
- `yakuake/kns_skins/Zephyr {Lauds,Compline}/`: Yakuake skins, recoloured from Slate by TheBigWazz.
- `apps/vivaldi/`: `zephyr-{lauds,compline}.json` are the sources, the committed `.zip`s are built
  from them by `build.sh`. `apps/slack/zephyr-themes.md`: the sidebar theme strings, pasted by hand
  (Slack keeps them on its servers, so they can't be scripted).
- `scripts/`: the sync scripts, generators and packaging (see below). `scripts/asar-tool/` pins
  `@electron/asar` 4.2.0 for the Slack script (its `node_modules/` is gitignored, leave it alone).
- `systemd/user/zephyr-theme-sync.service.in`: unit template, `@REPO@` is filled in by `install.sh`.
- `docs/kde-store.md` (store listing text, licences, credits), `docs/setup.jpg` (used in the README).
- Gitignored: `dist/` (store archives), `__pycache__/`, `scripts/asar-tool/node_modules/`.

## Install, test, release

- `./install.sh`: **copies** (it doesn't symlink) the schemes, styles, global themes, Konsole files and
  Yakuake skins into `${XDG_DATA_HOME:-~/.local/share}`, then builds `Colloid-Zephyr-Lauds/-Compline` from
  `Colloid-Light/-Dark` (looks in `~/.local/share/icons`, then `/usr/share/icons`, and skips with a
  message if Colloid isn't there). `--sync` also renders the unit into `~/.config/systemd/user/`,
  runs `daemon-reload` and `enable --now`. `--uninstall` disables the unit and deletes everything it
  installed. `-h` prints the header. It never needs root.
- After editing anything under `plasma/` or `yakuake/`, nothing changes on the desktop until
  `./install.sh` runs again. Only ask the user to run install.sh or systemctl, or do it yourself
  when they say so.
- Colour schemes: edit the palette and role mapping in `scripts/gen-compline-colors.py`, never the
  `.colors` files. Then run `python3 -I scripts/gen-compline-colors.py plasma/color-schemes`. To see
  the result live, switch to another scheme and back:
  `plasma-apply-colorscheme BreezeLightLowContrast && plasma-apply-colorscheme ZephyrLauds` (from
  the script's docstring).
- Icons: `python3 -I scripts/gen-muted-icons.py --src Colloid-Light --name Colloid-Zephyr-Lauds
  [--saturation 0.5] [--src-dir /usr/share/icons]`. The output goes to `~/.local/share/icons` and is
  never committed.
- Wallpaper: `scripts/gen-zephyr-wallpaper.sh SOURCE-PACKAGE [OUT]` (needs ffmpeg) writes a muted
  `<name> Zephyr` package. No wallpaper ships in the repo.
- Previews: `scripts/make-lnf-previews.sh [theme...]` switches global themes, screenshots the screen
  (spectacle and ImageMagick `magick`) and writes into `contents/previews/`. Whatever is on screen
  ends up in the repo, so this is for the owner to run.
- Vivaldi: edit the `.json`, run `apps/vivaldi/build.sh` (needs `zip`), and commit both files.
- KDE Store: `scripts/make-store-packages.sh` puts 8 tarballs in `dist/` (the table is in
  `docs/kde-store.md`). Uploading is done by hand.
- Checking sync changes: each module runs by hand, e.g. `scripts/konsole-theme-sync.sh dark`,
  `scripts/sysmon-color-sync.sh light`, `scripts/slack-tray-theme.sh build|restore|light|dark`.
  Syntax check: `bash -n scripts/*.sh`. There's no test suite or CI.
- Logs: `journalctl --user -u zephyr-theme-sync.service` (module stderr ends up here, e.g.
  `module failed: …`, `yakuake: skin '…' isn't installed`, `konsole: … refused setProfile`).

## How the light/dark sync works

- `zephyr-theme-sync.service` (`Restart=always`, `WantedBy=graphical-session.target`) runs
  `scripts/theme-watch.sh` **from this checkout** (absolute path written into the unit).
- `theme-watch.sh` is the single watcher. It runs one `gdbus monitor` on `org.freedesktop.portal.Desktop`
  and filters for `color-scheme` / `'ColorScheme'` signals. It reads `org.freedesktop.appearance
  color-scheme` (1 = dark, anything else = light) and `org.kde.kdeglobals.General ColorScheme` with
  `qdbus6`, and dispatches only when `mode:scheme` has changed. It also syncs once at startup. Modules
  are listed in `MODULES`, called as `<script> light|dark`, run concurrently and then `wait`ed, and
  each one's failure is caught so it can't kill the watcher. To add a module, add it to `MODULES`.
- `konsole-theme-sync.sh`: for the scheme `ZephyrLauds`/`ZephyrCompline` it uses
  `Profile - Zephyr <X>` and Yakuake skin `Zephyr <X>`. For any other scheme it uses `Profile - Light`/
  `Profile - Dark` (the user's own profiles, not shipped here) and still a Zephyr skin, picked by light or
  dark. It writes `[LightDarkTheme]` Light/DarkThemeProfile (Konsole ≥ 26.08) and `[Desktop Entry]
  DefaultProfile` into `konsolerc` and `yakuakerc`. It writes `yakuakerc [Appearance] Skin` only if the
  skin directory exists under `yakuake/kns_skins`, plus `BackgroundColor` from the profile's
  colorscheme. Then it switches live sessions over D-Bus (`org.kde.konsole-*`, `org.kde.yakuake`,
  `Session.setProfile`) and reads each one back, because a call that is silently ignored also returns 0.
- `sysmon-color-sync.sh`: repaints the `cpu/all/usage` and `memory/physical/usedPercent` bars of every
  `org.kde.plasma.systemmonitor` widget to the active scheme's `[Colors:View] ForegroundNormal`. It does
  this through `org.kde.PlasmaShell.evaluateScript`, because plasmashell overwrites outside
  kwriteconfig6 writes to the appletsrc.
- `slack-tray-theme.sh` (`set -euo pipefail`): only for the `--user` Flatpak `com.slack.Slack`. It
  builds light and dark copies of `app.asar` with the tray PNG data-URLs replaced by Colloid's
  `slack-indicator*` icons, rendered with `rsvg-convert` from `~/.local/share/icons/Colloid-{Light,Dark}/status/22`.
  The copies are cached in `~/.cache/slack-tray-theme` and keyed by the stock asar's sha256. The script
  swaps them in atomically (copy, then rename) and never restarts Slack, so the icon changes on Slack's
  next start. A Slack version that can't be patched is remembered in `unsupported.sha256`. Needs node,
  npm (installs asar-tool on first use) and rsvg-convert.
- Runtime tools: `qdbus6`, `gdbus`, `stdbuf`, `kreadconfig6`/`kwriteconfig6`, `python3`.

## Conventions

- Bash with `#!/usr/bin/env bash`. The sync modules use `set -u` (one failed step mustn't stop the
  others). Build and packaging scripts and the Slack script use `set -euo pipefail`. Scripts find the
  repo with `REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`. A header comment says why the
  script exists and how to run it, and the comments in the code explain the why. Python runs as `python3 -I`.
- Naming: **Lauds = light, Compline = dark**, everywhere. The exceptions are the Plasma styles
  (`zephyr-light`/`zephyr-dark`, shown as "Zephyr Light/Dark") and the source Colloid themes. Scheme
  ids have no space (`ZephyrLauds`), file and display names do (`Zephyr Lauds`).
- Licence: GPL-3.0 (`LICENSE`). The Plasma styles are LGPL (Breeze shapes). Only `install.sh` has an
  SPDX header (`GPL-3.0-only`, `2026 Jakub Lipiński <lipinski.j@pm.me>`). Keep the credits to
  Compline, Colloid and Slate in the README and the store text.
- Prose (README, docs, commits) is in the owner's voice: short plain clauses, colons, British "colour"
  (KDE keys stay `Color`).
- Commits: `<Area>: <what, in lowercase plain words>`, e.g. `Yakuake sync: only a skin that's
  installed, else say so in the log`, `Vivaldi: the script that builds the themes' zips`. Add an
  optional short body saying why, and the `Co-Authored-By` trailer.

## Gotchas

- The theme was split out of the owner's `linux-configs` into this repo, and some leftovers remain:
  `slack-tray-theme.sh` falls back to `$REPO/ikonki/slack/slack-tray-*.png`, which doesn't exist here
  (that fallback only runs when the Colloid SVG or rsvg-convert is missing). `make-lnf-previews.sh`
  stops and starts `theme-sync.service`, not `zephyr-theme-sync.service`, so as written it doesn't
  pause the sync. The comment in `theme-watch.sh` mentions the old per-app units it replaced.
- The Yakuake skins used to be Slate and were renamed to Zephyr Lauds/Compline. The sync then broke
  because `install.sh` hadn't been run again, so the skins were missing from
  `~/.local/share/yakuake/kns_skins`, and Yakuake silently falls back to its default skin.
  `konsole-theme-sync.sh` now only sets a skin that is installed and logs otherwise (commits `74033a9`,
  `00b5ac1`). After renaming or adding any installed piece, run `./install.sh` again.
- The service runs the scripts from this checkout. If the repo moves, run `./install.sh --sync` again.
  The modules are read again on every switch, but changes to `theme-watch.sh` itself need
  `systemctl --user restart zephyr-theme-sync.service`.
- Switching live Konsole/Yakuake profiles needs `[KonsoleWindow] EnableSecuritySensitiveDBusAPI=true`
  in `konsolerc` and `yakuakerc`, read when the app starts. Without it the call is refused or ignored,
  and the script logs it once per service.
- Yakuake skins only apply when Yakuake restarts, because there's no D-Bus call to reload them.
- The portal's light/dark alone doesn't tell the variants apart. Zephyr Dark → Zephyr Compline fires
  only `ColorScheme`, so the watcher keys on mode plus scheme name.
- The global themes carry the owner's panel layout. Changing `layout.js` changes other people's panels
  (Plasma asks before applying it).
- `make-store-packages.sh` deletes `dist/` and builds it again from scratch.

## Related

No code in the other repos under the parent `plasma/` folder depends on this one. The README's
"My setup" section links the owner's widgets that are checked out next to it: `glance-plasmoid`,
`taskline-plasmoid`, `eventcalendar-plasmoid` (Event Calendar NG), `karousel-overview`,
`focus-plasmoid` (Fokus) and `shift-plasmoid`. Their links in the README are kept up to date by hand
(e.g. `b21f5d9`).
