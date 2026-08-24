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

say "installing plugin to $PLUGIN_DIR"
mkdir -p "$PLUGIN_DIR"
cp -f "$REPO_DIR"/manifest.json "$REPO_DIR"/*.qml "$REPO_DIR"/SpacesLogic.js "$PLUGIN_DIR/"

WS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/io.github.samy104.spaces-workspaces"
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

if [ "${1:-}" = "--with-url-handler" ]; then
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

say "done. Enable the bar widget with:"
say "  omarchy plugin enable $PLUGIN_ID"
say "  omarchy plugin enable io.github.samy104.spaces-workspaces   # replaces omarchy.workspaces"
say "  omarchy plugin disable omarchy.workspaces"
say "  omarchy restart shell"
