# Apps and segmentation

An app belongs to one space. That does two things: its notifications are routed
to that space, and its windows open on that space's workspaces wherever you
launch it from.

```json
"apps": ["Signal", "Spotify"]
```

Launch Steam while work is active and it still lands on a personal workspace,
silently, without pulling you there.

## How placement works

`omarchy-spaces keybinds install` writes Hyprland window rules alongside the
bindings, generated from every space's `apps` list:

```lua
o.window("^(steam)$", { workspace = "4 silent" })
o.window("^(Slack)$", { workspace = "11 silent" })
```

Static rules rather than a daemon watching window-open events. Hyprland places
the window correctly the first time, so there is no visible jump, and there is
nothing left running.

Preview before applying:

```bash
omarchy-spaces windowrules show     # which app lands where
omarchy-spaces windowrules print    # the generated Lua
```

## The long form

A bare string covers the common case where the notification name and the window
class are the same text. When they are not, or you want more control:

```json
"apps": [
  "Signal",
  { "name": "Steam", "class": "steam", "slot": 4 },
  { "name": "Brave-browser", "windowRule": false },
  { "name": "YouTube Music", "class": "ytmusic", "shared": true }
]
```

| Field | Meaning |
|---|---|
| `name` | Matches the `app_name` a notification carries |
| `class` | Matches the Hyprland window class. Defaults to `name` |
| `slot` | Which workspace of the owning space its windows open on. Defaults to 1 |
| `windowRule` | Set false to route notifications but never move windows |
| `shared` | Belongs to no space. See below |

## Browsers need `windowRule: false`

Every profile of a browser shares one window class, so a placement rule on
`Brave-browser` drags your work profile's windows into your personal space. The
browser is already per space through `browser.profile`, so it does not need a
window rule at all.

`omarchy-spaces validate` catches this:

```
warn: personal: 'Brave-browser' is a browser used by a space; a window rule on
      it would pull every profile into personal. Set "windowRule": false on that
      entry to keep notification routing without the placement.
```

## Shared apps

Some apps belong to no space. A music player is the obvious one: you want it in
both spaces, you want its notifications either way, and you do not want its
window yanked around when you switch.

```json
"defaults": {
  "apps": [ { "name": "YouTube Music", "class": "ytmusic", "shared": true } ]
}
```

A shared app is owned by nobody, so `spaceForApp` returns nothing for it, its
notifications always get through, and no window rule is generated.

Shared entries are read from `defaults.apps` **directly**, not through
inheritance. Arrays replace when inherited, so a space with its own `apps` list
would otherwise never see a shared entry in defaults, which is exactly where
people will put one. This is the one place inheritance is deliberately
bypassed.

## Finding the right names

The notification name and the window class are different things and are often
different strings.

```bash
# what an app calls itself in notifications
ls -t ~/.local/state/omarchy/notifications/history/*.json | head -1 | \
  xargs python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['app'])"

# window classes of what is open now
hyprctl clients -j | python3 -c "
import json,sys
for c in json.load(sys.stdin): print(c['class'])"
```

The config app's app picker lists both, labelled by source, with names seen in
notifications ranked first.
