# Creating a space

Spaces live in the `spaces` array of `~/.config/omarchy-spaces/spaces.json`.
Adding one means adding an object to that array.

## The smallest useful space

```json
{
  "id": "side",
  "name": "Side project",
  "icon": "󰂜",
  "color": "#e0af68",
  "apps": ["Discord", "Figma"],
  "notifications": { "allowFrom": ["side"] }
}
```

`id` is the only required field. Everything else has a default.

## Every field

| Field | Meaning |
|---|---|
| `id` | Stable identifier. Used by the CLI, hotkeys, and `allowFrom`. Do not rename it casually. |
| `name` | Display name in the bar, picker, and status output. Defaults to `id`. |
| `icon` | Glyph shown in the bar. Any Nerd Font codepoint. |
| `color` | Accent color. Currently unused by the bar widget, reserved. |
| `browser.command` | Executable, for example `brave` or `google-chrome-stable`. |
| `browser.profile` | Passed as `--profile-directory`. |
| `browser.args` | Extra flags, inserted before the profile flag. |
| `email` | Address for this space. Readable with `omarchy-spaces get email`. |
| `assistants` | Map of tool name to account name. |
| `apps` | App names this space owns. Matched case insensitively. |
| `notifications.allowFrom` | Baseline list of space ids whose notifications show. |
| `notifications.allowUnassigned` | Whether apps in no space get through. Defaults to true. |
| `notifications.schedule` | Time windows that override the baseline. |

## A complete example

```json
{
  "id": "work",
  "name": "HiScale",
  "icon": "󰌛",
  "color": "#9ece6a",
  "browser": { "command": "brave", "profile": "Profile 1" },
  "email": "you@company.com",
  "assistants": { "claude": "work", "codex": "work" },
  "apps": ["Slack", "zoom", "google-chrome", "Thunderbird"],
  "notifications": {
    "allowFrom": ["work"],
    "allowUnassigned": false,
    "schedule": [
      { "from": "08:00", "to": "18:00", "allowFrom": ["work"], "label": "Work hours" },
      { "from": "18:00", "to": "08:00", "allowFrom": [], "allowUnassigned": false, "label": "Off hours" }
    ]
  }
}
```

## Finding the right app name

`apps` matches the `app_name` a program sends over D-Bus, not the window title
or the desktop file name. Trailing `.desktop` is stripped and case is ignored,
so `Slack`, `slack`, and `slack.desktop` all match.

To see what an app actually reports, send yourself a notification and read the
history:

```bash
ls -t ~/.local/state/omarchy/notifications/history/*.json | head -1 | \
  xargs python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['app'])"
```

Or test a name directly:

```bash
notify-send -a Slack "test" "does this show"
```

## After adding one

```bash
omarchy-spaces validate      # catches typos and schedule gaps
omarchy-spaces install-menu  # add the new row to the picker
omarchy-spaces list
```

The bar widget and the running shell pick up config changes on their own. No
restart needed.

Add a hotkey for it too, see [Hotkeys](Hotkeys).

## Choosing an icon

Icons are Nerd Font glyphs. Browse them at
[nerdfonts.com/cheat-sheet](https://www.nerdfonts.com/cheat-sheet). Paste the
glyph straight into the JSON. If it shows as a box or a stray digit, the
codepoint is outside the font, so pick another.
