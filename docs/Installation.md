# Installation

## Install

```bash
git clone https://github.com/Samy104/omarchy-spaces.git
cd omarchy-spaces
./install.sh
```

`install.sh` copies the shell plugin to
`~/.config/omarchy/plugins/io.github.samy104.omarchy-spaces/`, installs the CLI
to `~/.local/bin/omarchy-spaces`, writes a starter config if you have none,
enables the plugin, and validates the result.

Everything lands under `$HOME`. No sudo, nothing system wide.

It also installs the GTK4 config app when python-gobject and libadwaita are
present. It shows up in your launcher as "Omarchy Spaces", or run
`omarchy-spaces-config`.

## What a plain install does not touch

Nothing of Omarchy's own changes unless you ask for it.

| Option | What it also does |
|---|---|
| `--with-url-handler` | Links open in the active space's browser, which reassigns your default browser |
| `--replace-workspaces` | Swaps in the slot-numbered workspace widget, which **disables `omarchy.workspaces`** |
| `--all` | Both |

`./install.sh --help` lists them.

## The workspace widget, and what it replaces

This is the one step that turns off something of Omarchy's own, so it waits to
be asked, and it is worth understanding before you ask.

**Why it exists.** Omarchy's own workspace widget only knows workspaces 1 to
10. Its list is seeded with 1 to 5 and accepts ids `> 0 && <= 10`. A second
space uses real workspaces 11 to 20, so the widget cannot show where you are.

Stock widget, work space active, sitting on real workspace 19:

![Omarchy's widget in a second space](https://raw.githubusercontent.com/Samy104/omarchy-spaces/main/docs/screenshots/ws-stock.png)

It draws 1 to 6, highlights nothing, and marks nothing occupied. The workspace
you are on is not in its list.

**If you enable ours without disabling theirs**, both draw:

![Both widgets enabled](https://raw.githubusercontent.com/Samy104/omarchy-spaces/main/docs/screenshots/ws-both.png)

Two runs of numbers. The first is Omarchy's, dim and inert. The second is ours.
That is why `--replace-workspaces` does both halves rather than only enabling.

**After the swap:**

![The slot-numbered widget](https://raw.githubusercontent.com/Samy104/omarchy-spaces/main/docs/screenshots/ws-ours.png)

Slots 1 to 5, plus any other slot holding a window, with the focused slot drawn
as a dot rather than a number. That is how Omarchy's own widget marks focus, so
it should look familiar.

These are slots within the active space. The bar reads 1 to 10 in every space,
while the real workspaces underneath are 1 to 10 in personal and 11 to 20 in
work.

**To undo it:**

```bash
omarchy plugin enable omarchy.workspaces --section left
omarchy plugin disable io.github.samy104.omarchy-spaces-workspaces
```

Your spaces are unaffected either way. This widget only draws numbers; the
isolation itself does not depend on it.

## Enable the bar widget

`install.sh` enables it already. If you skipped that with
`OMARCHY_SPACES_NO_ENABLE=1`:

```bash
omarchy plugin enable io.github.samy104.omarchy-spaces
omarchy restart shell
```

The widget lands in the right section of the bar and shows the active space.
Move it with `omarchy bar move io.github.samy104.omarchy-spaces --section left`.

## Add the picker

```bash
omarchy-spaces install-menu
```

This splices a delimited block into
`~/.config/omarchy/extensions/omarchy-menu.jsonc`, one row per space with a
check mark on the active one, plus a "Space settings" row that opens the
configuration app. Your own entries and comments are left alone.
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
omarchy plugin disable io.github.samy104.omarchy-spaces
omarchy-spaces remove-menu
rm -rf ~/.config/omarchy/plugins/io.github.samy104.omarchy-spaces
rm -f ~/.local/bin/omarchy-spaces ~/.local/bin/omarchy-spaces-config
rm -f ~/.local/share/applications/omarchy-spaces-open.desktop
rm -f ~/.local/share/applications/omarchy-spaces-config.desktop
```

Your config at `~/.config/omarchy-spaces/` is left in place. Delete it if you
want a clean slate.
