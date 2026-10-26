#!/usr/bin/env bash
# Draws the Bright Future wallpapers from nothing: bash emits SVG, librsvg
# rasterises it, ImageMagick derives the theme's preview/unlock stills.
# Deps: librsvg (rsvg-convert), imagemagick (magick). The PNGs are committed,
# so this only runs again when the art changes.
#
# The art obeys the palette model in PALETTE.md: ~90% of the canvas is dark,
# glow is stepped (stacked ellipses, not fog), both accents appear in every
# major object, and the only smooth gradient is the near-invisible sky ramp.
# The accents behave like light sources something in the scene is producing —
# never like paint. The Omarchy wordmark paths are inlined from
# /usr/share/omarchy/logo.svg (basecamp/omarchy, MIT).
set -euo pipefail

. "$(dirname "$0")/../lib/theme.sh"
SRC_DIR="$THEME_ROOT/backgrounds/src"
BG_DIR="$THEME_ROOT/backgrounds"
ROOT_DIR="$THEME_ROOT"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

W=3840 H=2160 HORIZON=1652 VPX=1920

A="#ff4fd1"      # signal — hot magenta
A_HI="#ff8ae2"
B="#45e5ff"      # depth — electric cyan
B_HI="#7deeff"
CORE="#ffd9f4"   # near-white horizon core
STAR_DIM="#8b95d6"
STAR_HOT="#f2f4ff"
MASS="#04040b"   # silhouette black — darker than any sky stop

rect()    { printf '<rect x="%d" y="%d" width="%d" height="%d" fill="%s" opacity="%s"/>\n' "$@"; }
ellipse() { printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="%s" opacity="%s"/>\n' "$@"; }
line()    { printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="%s" opacity="%s"/>\n' "$@"; }

svg_open()  { printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' "$W" "$H" "$W" "$H"; }
svg_close() { printf '</svg>\n'; }

defs() {
  cat <<'DEFS'
<defs>
<pattern id="scan" width="4" height="4" patternUnits="userSpaceOnUse"><rect width="4" height="1" fill="#000000"/></pattern>
<radialGradient id="vig" cx="50%" cy="47%" r="72%"><stop offset="60%" stop-color="#000000" stop-opacity="0"/><stop offset="100%" stop-color="#000000" stop-opacity="0.40"/></radialGradient>
<filter id="soft" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="70"/></filter>
<filter id="soft2" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="150"/></filter>
<filter id="lineglow" x="-20%" y="-400%" width="140%" height="900%"><feGaussianBlur stdDeviation="7"/></filter>
</defs>
DEFS
}

# The Omarchy wordmark, verbatim from /usr/share/omarchy/logo.svg (1215x285).
# Emitted bare (no fill) so callers can use it as a clip or paint it.
omk_paths() {
  cat <<'OMK'
<path clip-rule="evenodd" fill-rule="evenodd" d="m720 120h-15v15h-14.998v14.999l-60.002.001v15.002l90-.002v.002h.002l-.002 89.998h-15v15h-13v15h-17v-89.998h-45v90l-45-.002v-89.998h-14.998v-30h14.998v-15.002h-14.998v-30.001h14.998v-75h15v-14.997h15v-15.002h105.002zm-90-.001h45v-74.997h-45z"/>
<path clip-rule="evenodd" fill-rule="evenodd" d="m105 30.002h15v14.997h15v180.001h-15v15h-15v15.002h-75v-15.002h-15v-15h-15v-180.001h15v-14.997h15v-15.002h75zm-60 194.998h45v-179.998h-45z"/>
<path d="m300 15h60v15h15v14.999h15v180.001h-15v15h-15v15h-15l-.004-209.998h-44.994v-.002h-.002v210.002h-45v-210h-44.998v179.997h-.002v30.003h-15v-15.002h-15v-15h-14.998v-180.001h14.998v-14.999h15v-15h60v-15h45z"/>
<path clip-rule="evenodd" fill-rule="evenodd" d="m555 225h-15v15h-15v15h-15v-105.001l-44.998.001v105.002h-45.002v-105.002h-15v-30.001h15v-75h15.002v-14.997h15v-15.002h105zm-89.998-105.001h44.998v-74.997h-44.998z"/>
<path d="m885 75h-15v15h-15v15h-15v-59.998h-45v179.998h45v-59.998h15v14.997h15v15.001h15v30h-15v15h-15v15.002l-105-.002v-210.001h14.998v-14.997h15.002v-15.002h105z"/>
<path d="m960 119.999h45v-104.999h15v15h15v14.999h15v75.001h15v15h-15v90h-15v15h-15v15h-15v-105h-45v105.002l-45-.002v-105h-30v-15h15v-15.001h15v-75h15v-14.997h15v-15.002h15z"/>
<path d="m1125 119.999h45v-104.999h15v15h15v15h15v180h-15v15h-15v15.002l-75-.002v-15h-15v-15h-15v-45.001h15v-14.997-.002h30v60h45v-75h-90v-105.001h15v-14.997h15v-15.002h15z"/>
OMK
}

overlay() {
  rect 0 0 "$W" "$H" 'url(#scan)' 0.12
  printf '<rect x="0" y="0" width="%d" height="%d" fill="url(#vig)"/>\n' "$W" "$H"
}

sparkle() { # x y halo-colour — plus-shaped pixel star with a tight square halo
  local x=$1 y=$2 halo=$3
  rect $((x - 9)) $((y - 9)) 18 18 "$halo" 0.12
  rect $((x - 7)) $((y - 2)) 14 4 "$STAR_HOT" 0.92
  rect $((x - 2)) $((y - 7)) 4 14 "$STAR_HOT" 0.92
}

fringe_sparkle() { # x y — same star, split by chromatic aberration
  local x=$1 y=$2
  rect $((x - 9)) $((y - 2)) 14 4 "$A" 0.45
  rect $((x - 5)) $((y - 2)) 14 4 "$B" 0.45
  rect $((x - 2)) $((y - 9)) 4 14 "$A" 0.45
  rect $((x - 2)) $((y - 5)) 4 14 "$B" 0.45
  rect $((x - 6)) $((y - 2)) 12 4 "$STAR_HOT" 0.90
  rect $((x - 2)) $((y - 6)) 4 12 "$STAR_HOT" 0.90
}

starfield() { # count ymin ymax — dim indigo mass, ~30% accent chroma, few sparkles
  local n=$1 ymin=$2 ymax=$3
  local i x y roll s
  local dims=("0.20" "0.30" "0.40" "0.50")
  for ((i = 0; i < n; i++)); do
    x=$((RANDOM * W / 32768))
    y=$((ymin + RANDOM * (ymax - ymin) / 32768))
    roll=$((RANDOM % 100))
    if ((roll < 62)); then
      s=$((1 + RANDOM % 3))
      rect "$x" "$y" "$s" "$s" "$STAR_DIM" "${dims[RANDOM % 4]}"
    elif ((roll < 78)); then
      s=$((2 + RANDOM % 2))
      rect "$x" "$y" "$s" "$s" "$B" 0.50
    elif ((roll < 88)); then
      s=$((2 + RANDOM % 2))
      rect "$x" "$y" "$s" "$s" "$A" 0.50
    elif ((roll < 96)); then
      if ((i % 2)); then sparkle "$x" "$y" "$A"; else sparkle "$x" "$y" "$B"; fi
    else
      fringe_sparkle "$x" "$y"
    fi
  done
}

horizon_glow() { # stacked ellipses under blur: banded falloff, no ring artifacts
  printf '<g filter="url(#soft)">\n'
  ellipse "$VPX" "$HORIZON" 2100 480 "$A" 0.030
  ellipse "$VPX" "$HORIZON" 1500 330 "$A" 0.045
  ellipse "$VPX" "$HORIZON" 1020 220 "$A" 0.075
  ellipse "$VPX" "$HORIZON" 640 130 "$A" 0.10
  ellipse "$VPX" "$HORIZON" 360 70 "$A_HI" 0.13
  printf '</g>\n'
  printf '<g filter="url(#lineglow)">\n'
  rect 660 $((HORIZON - 14)) 2520 28 "$A" 0.10
  rect 760 $((HORIZON - 7)) 2320 14 "$A" 0.26
  rect 860 $((HORIZON + 2)) 2120 8 "$A" 0.22
  printf '</g>\n'
  rect 860 $((HORIZON - 3)) 2120 5 "$CORE" 0.94
  # the depth accent answers at the line's far end — cross-pollination
  rect 2980 $((HORIZON - 2)) 150 3 "$B_HI" 0.45
}

counter_glow() { # cyan answer, top right — the 20-35% share of accent B
  printf '<g filter="url(#soft)">\n'
  ellipse 3350 160 1500 660 "$B" 0.040
  ellipse 3350 160 1000 430 "$B" 0.055
  ellipse 3350 160 620 250 "$B" 0.070
  printf '</g>\n'
}

RIDGE_PTS="0,1666 240,1652 520,1672 900,1640 1180,1668 1500,1690 1860,1700 2140,1682 2380,1660 2500,1664 2540,1690 2760,1690 2800,1662 3020,1648 3260,1668 3520,1642 3840,1658 3840,2160 0,2160"

ridge() { # near-black ground mass, bottom ~22% — the scene's physical anchor
  printf '<clipPath id="ridgeclip"><polygon points="%s"/></clipPath>\n' "$RIDGE_PTS"
  printf '<polygon points="%s" fill="%s"/>\n' "$RIDGE_PTS" "$MASS"
  # rim light where the dawn grazes the ridge line: signal near centre,
  # a cooler cyan answer out by the relay
  line 1500 1690 1860 1700 "$A" 3 0.10
  line 900 1640 1180 1668 "$A" 2 0.07
  line 2800 1662 3020 1648 "$B" 2 0.08
}

seams() { # the old grid, demoted: faint illuminated joints in an artificial ground
  local i xb
  printf '<g clip-path="url(#ridgeclip)">\n'
  for ((i = -3; i <= 3; i++)); do
    xb=$((VPX + i * 560))
    if ((i == -3 || i == 3)); then
      line "$VPX" "$HORIZON" "$xb" "$H" "$B" 3 0.05
    elif ((i == 0)); then
      line "$VPX" "$HORIZON" "$xb" "$H" "$A" 3 0.04
    else
      line "$VPX" "$HORIZON" "$xb" "$H" "$A" 3 0.06
    fi
  done
  line 0 1880 "$W" 1880 "$A" 2 0.045
  line 0 2060 "$W" 2060 "$A" 2 0.04
  rect 2560 1712 180 3 "$B" 0.07
  printf '</g>\n'
}

relay() { # one tiny structure, offset right — the thing producing the light
  # light spill on the plateau it stands on
  printf '<g filter="url(#lineglow)">\n'
  ellipse 2650 1692 100 10 "$A" 0.10
  printf '</g>\n'
  # silhouette blocks
  rect 2606 1642 88 48 "$MASS" 1
  rect 2622 1610 56 32 "$MASS" 1
  rect 2646 1470 8 140 "$MASS" 1
  rect 2610 1508 80 6 "$MASS" 1
  rect 2622 1546 56 6 "$MASS" 1
  # one magenta beacon, with a tight stepped halo
  printf '<g filter="url(#lineglow)">\n'
  ellipse 2650 1464 26 26 "$A" 0.22
  printf '</g>\n'
  rect 2644 1458 12 12 "$A" 0.95
  rect 2647 1461 6 6 "$CORE" 0.9
  # a sliver of cyan edge reflection on the mast's cold side
  rect 2654 1478 2 128 "$B_HI" 0.5
  rect 2678 1612 2 30 "$B" 0.4
}

bright_horizon() { # black ridge, one tiny relay, an impossibly bright thin dawn
  RANDOM=20260906
  svg_open
  cat <<'SKY'
<defs>
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#04040c"/>
<stop offset="0.45" stop-color="#0b0c19"/>
<stop offset="0.62" stop-color="#0c0c1e"/>
<stop offset="0.74" stop-color="#170f35"/>
<stop offset="0.765" stop-color="#0e0a22"/>
<stop offset="1" stop-color="#05050f"/>
</linearGradient>
</defs>
SKY
  defs
  printf '<rect x="0" y="0" width="%d" height="%d" fill="url(#sky)"/>\n' "$W" "$H"
  counter_glow
  starfield 50 40 1400
  horizon_glow
  ridge
  seams
  relay
  overlay
  svg_close
}

deep_field() { # nearly empty starfield; the wordmark hides in the star density
  RANDOM=19861219
  svg_open
  cat <<'SKY'
<defs>
<linearGradient id="sky" x1="0" y1="0" x2="0.2" y2="1">
<stop offset="0" stop-color="#04040c"/>
<stop offset="0.55" stop-color="#0b0c19"/>
<stop offset="1" stop-color="#100b24"/>
</linearGradient>
</defs>
SKY
  defs
  printf '<clipPath id="omkfield" transform="translate(420,700) scale(2.47)">\n'
  omk_paths
  printf '</clipPath>\n'
  printf '<rect x="0" y="0" width="%d" height="%d" fill="url(#sky)"/>\n' "$W" "$H"
  printf '<g transform="rotate(-16 1300 720)" filter="url(#soft2)">\n'
  ellipse 1300 720 1700 520 "$B" 0.045
  ellipse 1300 720 1150 340 "$B" 0.055
  ellipse 1300 720 700 200 "$B" 0.070
  printf '</g>\n'
  printf '<g transform="rotate(-16 2900 1500)" filter="url(#soft2)">\n'
  ellipse 2900 1500 1200 400 "$A" 0.045
  ellipse 2900 1500 800 260 "$A" 0.060
  ellipse 2900 1500 480 150 "$A" 0.080
  printf '</g>\n'
  starfield 175 20 $((H - 40))
  # an enormous, barely-perceptible glyph: extra star density clipped to the mark
  local i x y s
  printf '<g clip-path="url(#omkfield)">\n'
  rect 420 700 3001 704 "$STAR_DIM" 0.025
  for ((i = 0; i < 2200; i++)); do
    x=$((420 + RANDOM * 3001 / 32768))
    y=$((700 + RANDOM * 704 / 32768))
    s=$((1 + RANDOM % 2))
    if ((RANDOM % 100 < 88)); then
      rect "$x" "$y" "$s" "$s" "$STAR_DIM" "0.$((28 + RANDOM % 18))"
    else
      rect "$x" "$y" "$s" "$s" "$B" "0.$((30 + RANDOM % 16))"
    fi
  done
  printf '</g>\n'
  printf '<g transform="rotate(14 2600 380)">\n'
  rect 2180 378 560 3 "$B_HI" 0.35
  rect 2560 377 240 4 "$A_HI" 0.45
  printf '</g>\n'
  sparkle 2860 445 "$A"
  overlay
  svg_close
}

last_city() { # a distant black skyline, ~5% of the frame; the city is the light source
  RANDOM=20260907
  svg_open
  cat <<'SKY'
<defs>
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#04040c"/>
<stop offset="0.55" stop-color="#0b0c19"/>
<stop offset="0.92" stop-color="#141033"/>
<stop offset="1" stop-color="#0a0820"/>
</linearGradient>
</defs>
SKY
  defs
  printf '<rect x="0" y="0" width="%d" height="%d" fill="url(#sky)"/>\n' "$W" "$H"
  starfield 120 20 1780
  # the city's own glow, rising from behind the skyline — cyan mass, one warm answer
  printf '<g filter="url(#soft)">\n'
  ellipse 2400 2020 1700 200 "$B" 0.055
  ellipse 2400 2020 1100 130 "$B" 0.075
  ellipse 2400 2020 620 80 "$B_HI" 0.09
  ellipse 1150 2030 520 110 "$A" 0.06
  printf '</g>\n'
  # skyline: black towers, tiny cyan windows, one magenta beacon
  local x=0 w h top nw wx wy j
  while ((x < W)); do
    w=$((50 + RANDOM % 130))
    h=$((70 + RANDOM % 170))
    top=$((H - h))
    rect "$x" "$top" "$w" "$h" "$MASS" 1
    nw=$((RANDOM % 4))
    for ((j = 0; j < nw; j++)); do
      wx=$((x + 6 + RANDOM % (w > 18 ? w - 12 : 6)))
      wy=$((top + 10 + RANDOM % (h > 40 ? h - 30 : 10)))
      rect "$wx" "$wy" 3 4 "$B_HI" "0.$((30 + RANDOM % 45))"
    done
    x=$((x + w + RANDOM % 90))
  done
  # the tallest tower, its antenna, and the one magenta light in the city
  rect 1120 1880 74 280 "$MASS" 1
  rect 1132 1906 3 4 "$B_HI" 0.55
  rect 1168 1934 3 4 "$B" 0.45
  rect 1150 1820 6 60 "$MASS" 1
  printf '<g filter="url(#lineglow)">\n'
  ellipse 1153 1814 36 36 "$A" 0.30
  printf '</g>\n'
  rect 1148 1808 10 10 "$A" 0.95
  rect 1151 1811 4 4 "$CORE" 0.9
  overlay
  svg_close
}

omarchy_mark() { # virtually black; the wordmark catches the two lights
  RANDOM=20261219
  svg_open
  defs
  printf '<clipPath id="omkmark" transform="translate(705,795) scale(2.0)">\n'
  omk_paths
  printf '</clipPath>\n'
  rect 0 0 "$W" "$H" "#060711" 1
  starfield 45 30 $((H - 30))
  # the mark: a step above the ground, then each corner's light grazing it
  printf '<g clip-path="url(#omkmark)">\n'
  rect 705 795 2430 570 "#161936" 1
  printf '<g filter="url(#soft2)">\n'
  ellipse 950 1500 1100 560 "$A" 0.34
  ellipse 950 1500 640 330 "$A" 0.26
  ellipse 3000 740 1100 560 "$B" 0.30
  ellipse 3000 740 640 330 "$B" 0.22
  printf '</g>\n'
  printf '</g>\n'
  overlay
  svg_close
}

# The first three generators above are retained as design-source history, but
# are not part of the selected wallpaper set. Running this script must not
# recreate wallpapers that were deliberately removed from the theme.
omarchy_mark >"$TMP_DIR/omarchy.svg"

rsvg-convert -w "$W" -h "$H" -o "$BG_DIR/omarchy.png" "$TMP_DIR/omarchy.svg"

# preview.png is NOT derived here: bin/shoot-terminals owns it (a real capture
# of the applied theme). This script owns only the lock-screen stills.
echo "Rendered: $BG_DIR/omarchy.png"
