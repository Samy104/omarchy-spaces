# Hotkeys

## Defaults

Everything lives under SUPER + ALT, which Omarchy 4 leaves largely free.

| Keys | Action |
|---|---|
| SUPER + ALT + O | Open the Spaces picker |
| SUPER + ALT + N | Next space |
| SUPER + ALT + I | Show the current policy as a notification |
| SUPER + ALT + P | Switch to personal |
| SUPER + ALT + W | Switch to work |

## Installing them

Append to `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + ALT + O", "Spaces picker", "omarchy menu summon spaces")
o.bind("SUPER + ALT + N", "Next space", "omarchy-spaces next")
o.bind("SUPER + ALT + I", "Space status",
  "bash -lc 'omarchy-notification-send \"$(omarchy-spaces status)\"'")
o.bind("SUPER + ALT + P", "Space: Personal", "omarchy-spaces switch personal")
o.bind("SUPER + ALT + W", "Space: HiScale", "omarchy-spaces switch work")
```

Then apply and check:

```bash
hyprctl reload
hyprctl configerrors
```

An empty `configerrors` means it took.

## Adding a key for a new space

One line per space, pointing at the space `id`:

```lua
o.bind("SUPER + ALT + S", "Space: Side project", "omarchy-spaces switch side")
```

## Check for conflicts first

```bash
omarchy menu keybindings --print | grep "SUPER ALT"
```

SUPER + ALT is not entirely free in Omarchy 4. These are taken by default:

| Keys | Omarchy default |
|---|---|
| SUPER + ALT + SPACE | Apps menu |
| SUPER + ALT + arrows | Move window into a group |
| SUPER + ALT + TAB | Next window in group |
| SUPER + ALT + G | Move window out of group |
| SUPER + ALT + S | Move window to scratchpad |
| SUPER + ALT + 1 to 5 | Switch to group window |
| SUPER + ALT + brackets | Resize webcam overlay |

## Rebinding over an Omarchy default

Unbind first, otherwise both fire:

```lua
hl.unbind("SUPER + ALT + SPACE")
o.bind("SUPER + ALT + SPACE", "Spaces picker", "omarchy menu summon spaces")
```

## Mouse

The bar widget takes clicks too.

| Click | Action |
|---|---|
| Left | Open the picker |
| Right | Open the picker |
| Middle | Next space |

## Beyond hotkeys

Any of these commands works from a script, a terminal, or a hook. Switching is
just `omarchy-spaces switch <id>`, and every surface reads the same state file,
so the bar updates no matter where the switch came from.
