#!/usr/bin/env bash
# Install Omarchy Spaces: the shell plugin, the CLI, and optionally the URL
# handler. Everything lands under $HOME. No sudo, nothing system wide.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ID="io.github.samy104.omarchy-spaces"
PLUGIN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/$PLUGIN_ID"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"

say() { printf '  %s\n' "$*"; }

# Nothing outside this plugin's own files is touched unless asked for.
WITH_URL_HANDLER=0
REPLACE_WORKSPACES=0
for arg in "$@"; do
  case "$arg" in
    --with-url-handler)   WITH_URL_HANDLER=1 ;;
    --replace-workspaces) REPLACE_WORKSPACES=1 ;;
    --all)                WITH_URL_HANDLER=1; REPLACE_WORKSPACES=1 ;;
    -h|--help)
      cat <<'USAGE'
./install.sh [options]

  --with-url-handler     make links open in the active space's browser profile
                         (reassigns your default browser)
  --replace-workspaces   use the slot-numbered workspace widget instead of
                         Omarchy's own (disables omarchy.workspaces)
  --all                  both of the above

With no options nothing outside this plugin is changed.
USAGE
      exit 0 ;;
  esac
done

say "installing plugin to $PLUGIN_DIR"
mkdir -p "$PLUGIN_DIR"
cp -f "$REPO_DIR"/manifest.json "$REPO_DIR"/*.qml "$REPO_DIR"/SpacesLogic.js "$PLUGIN_DIR/"

WS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/io.github.samy104.omarchy-spaces-workspaces"
say "installing workspace widget to $WS_DIR"
mkdir -p "$WS_DIR"
cp -f "$REPO_DIR"/workspaces/* "$WS_DIR/"

say "installing CLI to $BIN_DIR/omarchy-spaces"
mkdir -p "$BIN_DIR"
install -m 0755 "$REPO_DIR/bin/omarchy-spaces" "$BIN_DIR/omarchy-spaces"

if python3 -c "import gi; gi.require_version('Adw','1')" 2>/dev/null; then
  say "installing the config app"
  install -m 0755 "$REPO_DIR/bin/omarchy-spaces-config" "$BIN_DIR/omarchy-spaces-config"
  mkdir -p "$APP_DIR"
  install -m 0644 "$REPO_DIR/share/omarchy-spaces-config.desktop" "$APP_DIR/"

  # Icon theme sizes rather than one file: a launcher picking 48px should not
  # have to downscale a 512px image every time it draws the grid.
  ICON_SRC="$REPO_DIR/assets/icon.png"
  if [ -f "$ICON_SRC" ]; then
    for size in 512 256 128 64 48 32; do
      dir="$HOME/.local/share/icons/hicolor/${size}x${size}/apps"
      mkdir -p "$dir"
      if command -v magick >/dev/null 2>&1; then
        magick "$ICON_SRC" -resize "${size}x${size}" -strip "$dir/omarchy-spaces.png"
      else
        install -m 0644 "$ICON_SRC" "$dir/omarchy-spaces.png"
      fi
    done
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
  fi
  update-desktop-database "$APP_DIR" 2>/dev/null || true
else
  say "skipping the config app, install python-gobject and libadwaita for it"
fi

if [ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/omarchy-spaces/spaces.json" ]; then
  say "writing starter config"
  "$BIN_DIR/omarchy-spaces" init
else
  say "config already exists, leaving it alone"
fi

if [ "$WITH_URL_HANDLER" = "1" ]; then
  say "installing URL handler and making it the default browser"
  mkdir -p "$APP_DIR"
  install -m 0644 "$REPO_DIR/share/omarchy-spaces-open.desktop" "$APP_DIR/omarchy-spaces-open.desktop"
  update-desktop-database "$APP_DIR" 2>/dev/null || true
  xdg-settings set default-web-browser omarchy-spaces-open.desktop
  say "links now route through the active space"
else
  say "skipping URL handler, pass --with-url-handler to enable link routing"
fi

say "validating config"
"$BIN_DIR/omarchy-spaces" validate || true

# Omarchy discovers exactly one manifest per third-party plugin directory, so a
# second bar widget has to live in its own folder. They are one package: same
# repo, same version, installed, enabled, and removed together.
WS_ID="io.github.samy104.omarchy-spaces-workspaces"

if [ "${OMARCHY_SPACES_NO_ENABLE:-}" = "1" ]; then
  say "skipping enable, OMARCHY_SPACES_NO_ENABLE is set"
else
  say "enabling"
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  sleep 1
  omarchy plugin enable "$PLUGIN_ID" >/dev/null 2>&1 || say "  enable $PLUGIN_ID failed, run it by hand"

  # The workspace widget replaces Omarchy's own, and turning off someone
  # else's widget is not something an installer should decide. Enabling ours
  # while theirs is still on would show two rows of numbers, so it waits to
  # be asked.
  if [ "$REPLACE_WORKSPACES" = "1" ]; then
    omarchy plugin enable "$WS_ID" >/dev/null 2>&1 || say "  enable $WS_ID failed, run it by hand"
    omarchy plugin disable omarchy.workspaces >/dev/null 2>&1 || true
    say "  workspace widget swapped in, Omarchy's own is now disabled"
  else
    say "  left Omarchy's workspace widget alone"
    say "  to show slot numbers instead of real workspace ids, re-run with"
    say "    ./install.sh --replace-workspaces"
  fi
fi

say "done. Apply with: omarchy restart shell"
