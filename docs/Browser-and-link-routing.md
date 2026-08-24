# Browser and link routing

Click a link in your terminal, chat app, or email client and it opens in the
browser profile belonging to the active space.

## Setup

```json
"browser": { "command": "brave", "profile": "Default" }
```

`command` is the executable. `profile` is passed as `--profile-directory`.
Optional `args` are inserted before the profile flag.

Then make the router your default browser:

```bash
./install.sh --with-url-handler
```

## Finding your profile directory names

They are directory names on disk, not the display names you see in the browser.

Brave:

```bash
python3 -c "
import json,os
d=json.load(open(os.path.expanduser('~/.config/BraveSoftware/Brave-Browser/Local State')))
for k,v in d['profile']['info_cache'].items(): print(k, '->', v.get('name'))
"
```

Chrome is the same with `~/.config/google-chrome/Local State`. Chromium uses
`~/.config/chromium/Local State`.

The first profile is always `Default`. The rest are `Profile 1`, `Profile 2`,
and so on. The space in `Profile 1` is fine, the CLI passes it as a single
argument.

## Checking without opening anything

```bash
omarchy-spaces which https://example.com
```

```json
["brave", "--profile-directory=Profile 1", "https://example.com"]
```

That is the exact argv it would run. Switch spaces and run it again to confirm
the routing changes.

## How it works

`omarchy-spaces-open.desktop` becomes the handler for `http`, `https`, and
`text/html`. Its `Exec` line is `omarchy-spaces open %u`. The CLI reads the
active space, builds the argv, and `exec`s the browser directly, so no extra
process stays around.

If the active space declares no browser, it falls through to `xdg-open`.

## Turning it off

```bash
xdg-settings set default-web-browser brave-browser.desktop
```

Or point at a specific profile so links always land in one place:

```bash
xdg-settings set default-web-browser brave-perso.desktop
```

## Per space browsers, not just profiles

Nothing requires the same browser everywhere:

```json
{ "id": "personal", "browser": { "command": "brave", "profile": "Default" } }
{ "id": "work",     "browser": { "command": "google-chrome-stable", "profile": "Profile 1" } }
```

## Extra flags

```json
"browser": {
  "command": "brave",
  "profile": "Profile 1",
  "args": ["--password-store=gnome-libsecret"]
}
```

On Hyprland that flag matters. Chromium detects the keyring backend from
`XDG_CURRENT_DESKTOP`, does not recognise `Hyprland`, and falls back to a store
that encrypts with a hardcoded key. Passing it explicitly puts saved passwords
in the real keyring.

## What this does not do

It routes links. It does not stop you opening the other profile by hand, and it
does not isolate cookies beyond what browser profiles already give you. The
separation is the browser's, this just picks which one.
