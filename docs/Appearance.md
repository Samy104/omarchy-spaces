# Appearance

A space can pin a theme, a monospace font, and a background. They are applied on
every switch, which makes the active context obvious without reading anything.

```json
"appearance": {
  "theme": "Catppuccin Latte",
  "font": "CaskaydiaMono Nerd Font",
  "background": "1-color-curves.jpg"
}
```

Every field is optional. Omit one and that part of your desktop is left alone.

## The easy way to set it

Get the desktop looking how you want using the normal Omarchy tools, then save
it to the active space:

```bash
omarchy-spaces appearance capture
```

The config app has the same thing as the "Capture current" button in the
Appearance section.

```bash
omarchy-spaces appearance show     # pinned vs live
omarchy-spaces appearance apply    # re-apply the pinned look
omarchy-spaces appearance clear    # stop pinning
```

## How it is applied

The plugin shells out to the stock commands, so anything Omarchy supports keeps
working:

```
omarchy theme set <name>
omarchy font set <name>
omarchy theme bg set <path>
```

Theme is applied first, because setting a theme also resets the background. A
pinned background applied before the theme would be immediately overwritten.

## Why backgrounds are stored as a filename

Backgrounds live in `~/.local/state/omarchy/current/theme/backgrounds/`, and
that directory's contents are replaced when the theme changes. Storing the
absolute path would silently point at the next theme's image.

So a background belonging to a theme is stored as a bare filename and resolved
after the theme is applied. An absolute path to an image anywhere else is stored
as is and used directly.

```json
"background": "2-coffee-beans.jpg"
"background": "/home/you/Pictures/wall.png"
```

If the file cannot be found at apply time, the background is skipped rather than
failing the switch.

## Finding names

```bash
omarchy theme list
omarchy font list
ls ~/.local/state/omarchy/current/theme/backgrounds/
```

Theme names are matched as Omarchy prints them, including spaces and case.

## Turning it off

```json
{ "applyAppearance": false }
```

at the top level. Pinned values are kept but not applied, which is useful while
you are still deciding.

## A suggestion

Pair a dark theme with one space and a light theme with the other. Peripheral
vision picks that up faster than any icon or label.
