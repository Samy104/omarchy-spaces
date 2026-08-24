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

## Workspaces

The numbers are slots within the active space, not real workspace ids, which is
how the higher ranges stay reachable. See
[Workspaces and windows](Workspaces-and-windows).

| Keys | Action |
|---|---|
| SUPER + 1 to 0 | Go to slot 1 to 10 of the active space |
| SUPER + SHIFT + 1 to 0 | Move the focused window to that slot |
| SUPER + ALT + SHIFT + P | Send the focused window to personal |
| SUPER + ALT + SHIFT + W | Send the focused window to work |

These replace Omarchy's own `SUPER+1..0` and `SUPER+SHIFT+1..0`, so the snippet
in `hypr/spaces.lua` unbinds them first:

```lua
for i = 1, 10 do
  local key = "code:" .. tostring(i + 9)
  hl.unbind("SUPER + " .. key)
  hl.unbind("SUPER + SHIFT + " .. key)
  o.bind("SUPER + " .. key, "Workspace " .. i .. " (this space)",
    "omarchy-spaces workspace " .. i)
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. i .. " (this space)",
    "omarchy-spaces move-to-workspace " .. i)
end
```

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

The picker lists every space, marks the active one, and ends with
"Space settings", which opens the configuration app. Clicking it again reuses
the same window rather than opening a second one.

## Beyond hotkeys

Any of these commands works from a script, a terminal, or a hook. Switching is
just `omarchy-spaces switch <id>`, and every surface reads the same state file,
so the bar updates no matter where the switch came from.
