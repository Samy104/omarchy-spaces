# Theming

The configuration app follows the Omarchy theme. Switch spaces, the theme
changes, and the app changes with it without being restarted.

## Where the colours come from

Omarchy writes the active theme to
`~/.local/state/omarchy/current/theme/colors.toml`, the same file the bar,
terminals, and editors read. The app reads it and overrides libadwaita's named
colours, so it matches the desktop rather than sitting in stock Adwaita while
everything around it is Ristretto or Osaka Jade.

| colors.toml | libadwaita |
|---|---|
| `background` | `window_bg_color` |
| `dark_background` | `view_bg_color`, `popover_bg_color` |
| `darker_background` | `headerbar_bg_color`, `sidebar_bg_color` |
| `lighter_background` | `card_bg_color` |
| `foreground` | every matching `_fg_color` |
| `accent` | `accent_bg_color`, `accent_color` |
| `red` | `destructive_*`, `error_*` |
| `green` | `success_*` |
| `yellow` | `warning_*` |
| `muted` | `.dim-label` |
| `mode` | forces the light or dark colour scheme |

Text on a filled button is picked by relative luminance rather than assumed
white, so a bright accent gets black text and stays readable.

## Following a change

The theme directory is watched, not the file. A theme change replaces the file
wholesale, and a rename swaps the inode out from under a file monitor, so
watching the file alone would miss it. This is the same trap the shell plugin
hit with its state file.

Reapplying is skipped when the palette has not actually changed, so touching
the directory does not rebuild the stylesheet for nothing.

## Turning it off

Delete or rename `colors.toml` and the app falls back to stock libadwaita. There
is no setting for this: an app that ignored the desktop theme by choice would be
a strange thing to offer.

## The shell plugin

The bar widget needs none of this. Quickshell plugins draw with Omarchy's own
`Color` and `Style` singletons, so the indicator and the workspace numbers
already follow the theme by construction. Only the GTK app had to be taught.
