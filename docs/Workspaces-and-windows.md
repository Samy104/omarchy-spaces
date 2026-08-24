# Workspaces and windows

Each space owns a contiguous range of real Hyprland workspaces. Personal gets 1
to 10, work gets 11 to 20. Windows are never moved when you switch, which is
what makes switching instant and free of races.

"Workspace 1" means a different real workspace depending on which space is
active. That is the isolation. Open a terminal on slot 1 in personal, switch to
work, and slot 1 there is empty.

## Seeing the mapping

```bash
omarchy-spaces windows
```

```
* Personal (personal)  real workspaces 1-10
      slot 1  foot                    ~/notes
      slot 3  brave-browser           Inbox
  HiScale (work)  real workspaces 11-20
      slot 1  Slack                   #engineering
```

Anything sitting outside every range is listed separately.

## Hotkeys

The numbers are slots within the active space, not real workspace ids. That is
what keeps the higher ranges reachable without inventing keys for 11 to 20.

| Keys | Action |
|---|---|
| SUPER + 1 to 0 | Go to slot 1 to 10 of the active space |
| SUPER + SHIFT + 1 to 0 | Move the focused window to that slot |
| SUPER + ALT + SHIFT + P | Send the focused window to personal |
| SUPER + ALT + SHIFT + W | Send the focused window to work |

`SUPER + SHIFT + 1` in work moves the window to real workspace 11. The same
keystroke in personal moves it to real workspace 1.

These replace Omarchy's own `SUPER+1..0` and `SUPER+SHIFT+1..0`, so
`hypr/spaces.lua` unbinds them first.

## Moving a window that opened in the wrong space

This is the common case. A link opens a browser window in personal while you are
working.

```bash
omarchy-spaces move-to-space work
```

The window leaves silently, so you stay where you are. Add `--follow` to go with
it. Add a slot number to choose where it lands:

```bash
omarchy-spaces move-to-space work 3
omarchy-spaces move-to-space work 3 --follow
```

Without a slot it keeps the same slot number it was already on, so a window on
personal slot 2 lands on work slot 2.

## Targeting a specific window

By default these act on the focused window, which is what a hotkey wants. For
scripts, pass an address from `hyprctl clients`:

```bash
omarchy-spaces move-to-space work --address 0x55c562ebb0f0
```

## Configuring ranges

Offsets are derived from each space's position in the list, so this works with
no configuration. To pin them:

```json
"workspaces": { "offset": 20, "count": 5 }
```

`offset` is the workspace before the first slot, so offset 20 with 5 slots means
real workspaces 21 to 25. `omarchy-spaces validate` fails if two spaces claim
the same real workspace.

## Turning it off

```json
{ "workspaceIsolation": false }
```

at the top level of the config. Switching then leaves your workspace alone and
only changes notifications, browser, and appearance.

## What the bar shows

Omarchy's workspace widget shows real workspace ids, so in the work space you
see 11 to 20 rather than 1 to 10. The numbers you press and the numbers on the
bar differ. This is cosmetic and on the list to improve.
