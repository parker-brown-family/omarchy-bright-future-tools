# Bright Future — tools

The scripts behind the [Bright Future](https://github.com/parker-brown-family/omarchy-bright-future-theme)
Omarchy theme: the wallpaper renders and the screenshot rig. They live apart
from the theme because a theme carries no code. Omarchy never runs anything in
one, and the theme gallery lists only themes that ship none.

## Setup

Clone both, side by side. The tools find the theme checkout next to them:

```bash
git clone https://github.com/parker-brown-family/omarchy-bright-future-theme
```
```bash
git clone https://github.com/parker-brown-family/omarchy-bright-future-tools
```

Anywhere else, point `BRIGHT_FUTURE_THEME` at the theme checkout.

## What is here

| Tool | What it does |
|---|---|
| `wallpapers/render.sh` | draws the Omarchy wordmark wallpaper from nothing: bash emits SVG, librsvg rasterises it |
| `wallpapers/conform-sourced.sh` | brings three of the source renders onto the palette: fill-crop to 4K, chroma trim, floor crushed to the void |
| `wallpapers/grade-night-shift.sh` | flattens Night Shift to grayscale and regrades it through a palette ramp |
| `bin/shoot-terminals` | stages fastfetch, the palette preview and btop on a spare workspace, shoots the monitor, and writes the theme's `screenshots/terminals.png` and `preview.png` |
| `bin/apply-live` | re-applies the theme, so an edit to `colors.toml` is what the desktop shows |
| `bin/backdrop` | points the desktop at one of the theme's backgrounds by file name, so a staged shot is deterministic |
| `bin/probe-dsp` | introspects Hyprland 0.56's Lua dispatch surface — the measurements `shoot-terminals` is built on |

The wallpaper scripts read the source renders from the theme's
`backgrounds/src/` and write into its `backgrounds/`. Run against the committed
sources, they reproduce the committed wallpapers pixel for pixel. They need
librsvg and ImageMagick; the screenshot rig also needs Hyprland, grim, jq,
foot, btop, fastfetch and wtype.

This repository began as a copy of the theme's, so the commits that built these
scripts are still here.

## Licence

MIT
