# Slack sidebar themes: Zephyr Lauds / Zephyr Compline

Slack stores the sidebar theme in your account (server-side), so it can't be
scripted. Paste one of these strings, either:

- into a message to yourself; Slack shows a **Switch sidebar theme** button, or
- in Preferences → Themes → custom theme.

Keep Slack's appearance on **Sync with OS setting**, so light/dark follows Plasma.
The custom sidebar theme is a single one (not separate for light and dark); use
Zephyr Lauds for daytime.

| Theme | String |
|---|---|
| Zephyr Lauds (light) | `#DEE0E2,#599DC0,#5A6B5A,#8B6666` |
| Zephyr Compline (dark) | `#1F2228,#98A4AC,#B8C4B8,#CDACAC` |

Order of the four colors: column background, active item, active presence,
mention badge.

- Lauds: header (Breeze grey), desaturated Breeze-blue accent, green, red from
  `plasma/color-schemes/ZephyrLauds.colors`.
- Compline: the upstream Compline Slack theme
  (github.com/joshuablais/compline, `slack/import.txt`).

The tray icon is themed separately by `scripts/slack-tray-theme.sh`.
