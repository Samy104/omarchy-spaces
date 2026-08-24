# Installation

## Install

```bash
git clone https://github.com/Samy104/omarchy-spaces.git
cd omarchy-spaces
./install.sh
```

`install.sh` does four things. It copies the shell plugin to
`~/.config/omarchy/plugins/spaces.omarchy-spaces/`, installs the CLI to
`~/.local/bin/omarchy-spaces`, writes a starter config if you have none, and
validates it.

Everything lands under `$HOME`. No sudo, nothing system wide.

## Enable the bar widget

```bash
omarchy plugin enable spaces.omarchy-spaces
omarchy restart shell
```

The widget lands in the right section of the bar and shows the active space.
Move it with `omarchy bar move spaces.omarchy-spaces --section left`.

## Add the picker

```bash
omarchy-spaces install-menu
```

This splices a delimited block into
`~/.config/omarchy/extensions/omarchy-menu.jsonc`, one row per space, with a
check mark on the active one. Your own entries and comments are left alone.
Re-run it whenever you add or rename a space. `omarchy-spaces remove-menu`
takes the block back out.

## Add hotkeys

Copy what you want from `hypr/spaces.lua` into `~/.config/hypr/bindings.lua`.
See [Hotkeys](Hotkeys) for the defaults and how to check for conflicts.

## Turn on link routing

Off by default, because it reassigns your default browser.

```bash
./install.sh --with-url-handler
```

That installs `omarchy-spaces-open.desktop` and makes it the default browser
handler. Links then go to the active space's browser profile. See
[Browser and link routing](Browser-and-link-routing).

To undo it, point the default browser back at a real browser:

```bash
xdg-settings set default-web-browser brave-browser.desktop
```

## Verify

```bash
omarchy-spaces validate
omarchy-spaces status
```

`validate` checks for schedule gaps, overlapping windows, and references to
spaces that do not exist. `status` prints the policy in effect right now.

## Uninstall

```bash
omarchy plugin disable spaces.omarchy-spaces
omarchy-spaces remove-menu
rm -rf ~/.config/omarchy/plugins/spaces.omarchy-spaces
rm -f ~/.local/bin/omarchy-spaces
rm -f ~/.local/share/applications/omarchy-spaces-open.desktop
```

Your config at `~/.config/omarchy-spaces/` is left in place. Delete it if you
want a clean slate.
