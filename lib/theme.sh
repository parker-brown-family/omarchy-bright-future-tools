# Sourced by every tool here, to find the theme they read from and write into.
#
# The theme is its own repository, parker-brown-family/omarchy-bright-future-theme,
# because a theme carries no code. These tools work on a checkout of it: the one
# BRIGHT_FUTURE_THEME names, or else the one cloned beside this repository.
tools_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_ROOT="${BRIGHT_FUTURE_THEME:-$(dirname "$tools_root")/omarchy-bright-future-theme}"
if [[ ! -f $THEME_ROOT/colors.toml ]]; then
  echo "no Bright Future theme checkout at $THEME_ROOT" >&2
  echo "  git clone https://github.com/parker-brown-family/omarchy-bright-future-theme $(dirname "$tools_root")/omarchy-bright-future-theme" >&2
  echo "  or point BRIGHT_FUTURE_THEME at one" >&2
  exit 1
fi
THEME_ROOT="$(cd "$THEME_ROOT" && pwd)"
