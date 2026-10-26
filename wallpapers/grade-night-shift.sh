#!/usr/bin/env bash
# Regrades one of the theme's GPT source renders. night-shift-src.png (pixel
# art, 1254x1254, warm cream + slate blue as rendered) is flattened to
# grayscale and pushed through a five-stop palette ramp — ground through material into
# cyan mids, with the hottest values (the doorway, the rim light) crossing into
# magenta — then centred on a 4K canvas matched to the art's own border black.
# Dep: imagemagick (magick). The PNG is committed; rerun only to change the grade.
set -euo pipefail

. "$(dirname "$0")/../lib/theme.sh"
SRC_DIR="$THEME_ROOT/backgrounds/src"
BG_DIR="$THEME_ROOT/backgrounds"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# 0%..100% ramp: ground -> raised indigo -> selection -> cyan depth -> magenta signal -> core
magick \
  \( -size 1x143 gradient:'#04040b-#10122b' \) \
  \( -size 1x113 gradient:'#10122b-#2a2d63' \) \
  \( -size 1x113 gradient:'#2a2d63-#38d2f5' \) \
  \( -size 1x82 gradient:'#38d2f5-#ff8ae2' \) \
  \( -size 1x61 gradient:'#ff8ae2-#fff0fb' \) \
  -append "$TMP_DIR/clut.png"

magick "$SRC_DIR/night-shift-src.png" -colorspace Gray "$TMP_DIR/clut.png" -clut \
  -resize 1800x1800 "$TMP_DIR/graded.png"

magick -size 3840x2160 xc:'#05050e' "$TMP_DIR/graded.png" -gravity center -composite \
  "$BG_DIR/4-night-shift.png"

echo "Rendered: $BG_DIR/4-night-shift.png"
