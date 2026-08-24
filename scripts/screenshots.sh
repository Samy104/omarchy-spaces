#!/usr/bin/env bash
# Regenerate the documentation screenshots.
#
# Everything is captured from an isolated demo profile in /tmp/omarchy-demo,
# built from docs/screenshots/demo-config.json, so no real email address,
# space name, or home directory can end up in a published image. The bar and
# picker come from the running shell, which reads the session's own config, so
# that one is swapped out and restored.
#
# Needs a running Hyprland session. Run it from the repo root.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEMO=/tmp/omarchy-demo
RAW="$(mktemp -d)"
OUT="$REPO/docs/screenshots"
BK="$(mktemp -d)"
SCRATCH_WS=9      # an empty workspace, so nothing behind leaks into a shot

for tool in grim magick hyprctl tesseract; do
  command -v "$tool" >/dev/null || { echo "need $tool"; exit 1; }
done

# --- demo profile ------------------------------------------------------------
rm -rf "$DEMO"
mkdir -p "$DEMO/.config/omarchy-spaces" "$DEMO/.local/state/omarchy-spaces" \
         "$DEMO/.local/state/omarchy/current"
cp "$OUT/demo-config.json" "$DEMO/.config/omarchy-spaces/spaces.json"
echo home > "$DEMO/.local/state/omarchy-spaces/active"
# Copy the live theme so the app is themed rather than stock Adwaita.
cp -r "$HOME/.local/state/omarchy/current/theme" "$DEMO/.local/state/omarchy/current/theme"

kill_app() {
  for p in $(pgrep -f 'omarchy-spaces-config' 2>/dev/null); do kill -9 "$p" 2>/dev/null || true; done
  sleep 1
}

win_field() {
  hyprctl clients -j | python3 -c "
import json,sys
for c in json.load(sys.stdin):
    if 'Spaces' in (c.get('class') or ''):
        x,y=c['at']; w,h=c['size']
        print(c['address'] if '$1'=='addr' else f'{x},{y} {w}x{h}')
        break"
}

shoot_app() {
  local page="$1" name="$2"
  kill_app
  HOME="$DEMO" XDG_CONFIG_HOME="$DEMO/.config" XDG_STATE_HOME="$DEMO/.local/state" \
    setsid omarchy-spaces-config --page "$page" </dev/null >/dev/null 2>&1 &
  sleep 8
  local a; a="$(win_field addr)"
  [ -n "$a" ] || { echo "  $name: no window"; return; }
  # Park it alone so the shot is the window, not whatever it tiled beside.
  hyprctl dispatch "hl.dsp.window.move({ workspace = \"$SCRATCH_WS\", window = \"address:$a\", follow = false })" >/dev/null
  hyprctl dispatch "hl.dsp.focus({ workspace = \"$SCRATCH_WS\" })" >/dev/null
  sleep 2
  grim -g "$(win_field geom)" "$RAW/$name.png"
  magick "$RAW/$name.png" -resize 1400x -strip -define png:compression-level=9 "$OUT/$name.png"
  echo "  $name"
}

echo "app pages"
shoot_app general  general
shoot_app 0        space
shoot_app 1        space-work
shoot_app keybinds keybinds
shoot_app defaults defaults
kill_app

# --- bar and picker come from the running shell ------------------------------
CFG="$HOME/.config/omarchy-spaces/spaces.json"
ACTIVE="$HOME/.local/state/omarchy-spaces/active"
MENU="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"

restore() {
  cp "$BK/spaces.json" "$CFG"
  cp "$BK/active" "$ACTIVE"
  cp "$BK/menu.jsonc" "$MENU"
  omarchy-spaces install-menu >/dev/null 2>&1 || true
  echo "  restored your own config"
}
trap restore EXIT

cp "$CFG" "$BK/spaces.json"; cp "$ACTIVE" "$BK/active"; cp "$MENU" "$BK/menu.jsonc"
cp "$DEMO/.config/omarchy-spaces/spaces.json" "$CFG"
echo home > "$ACTIVE"
omarchy-spaces install-menu >/dev/null 2>&1

echo "bar and picker"
# The shell re-reads through a watcher; give it room rather than racing it.
sleep 12
hyprctl dispatch "hl.dsp.focus({ workspace = \"$SCRATCH_WS\" })" >/dev/null
sleep 2
W=$(hyprctl monitors -j | python3 -c "import json,sys;m=json.load(sys.stdin)[0];print(int(m['width']/m['scale']))")
grim -g "0,0 ${W}x24" "$RAW/bar.png"
magick "$RAW/bar.png" -resize 1400x -strip "$OUT/bar.png"
grim -g "$((W-360)),0 360x24" "$RAW/bar-indicator.png"
magick "$RAW/bar-indicator.png" -resize 720x -strip "$OUT/bar-indicator.png"
echo "  bar"

omarchy menu summon spaces >/dev/null 2>&1 &
sleep 4
grim "$RAW/screen.png"
magick "$RAW/screen.png" -gravity center -crop 1000x680+0+0 +repage -resize 1000x -strip \
  "$OUT/picker.png"
omarchy-shell shell hide omarchy.menu >/dev/null 2>&1 || true
echo "  picker"

# --- verification ------------------------------------------------------------
# OCR is not reliable enough on small text to be the only defence, which is why
# the demo profile exists. It is a second pair of eyes, not the first.
echo "checking for anything personal"
PII='samy|hiscale|gmail\.com|/home/'
fail=0
for f in "$OUT"/*.png; do
  if tesseract "$f" - 2>/dev/null | grep -iqE "$PII"; then
    echo "  FAIL $(basename "$f")"
    tesseract "$f" - 2>/dev/null | grep -inE "$PII" | sed 's/^/        /'
    fail=1
  fi
done
[ "$fail" = 0 ] && echo "  clean"
rm -rf "$RAW"
exit "$fail"
