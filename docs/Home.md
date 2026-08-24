# Omarchy Spaces

Context spaces for [Omarchy](https://omarchy.org). A space is a named context
like Personal or Work. Each one owns a browser profile, an email address,
assistant accounts, and a notification policy. Switching spaces re-points all
of them at once.

Omarchy already has workspaces, which decide window layout. Spaces decide
identity. You can be on workspace 3 in either context, and the difference that
matters is whether a work message should interrupt your evening.

## Start here

- [Installation](Installation)
- [Creating a space](Creating-a-space)
- [Editing a space](Editing-a-space)
- [Defaults and inheritance](Defaults-and-inheritance)
- [Apps and segmentation](Apps-and-segmentation)
- [The default space](Default-space)
- [How notifications are routed](How-notifications-are-routed)
- [Workspaces and windows](Workspaces-and-windows)
- [Appearance](Appearance)
- [Keybinds](Keybinds)
- [Hotkeys](Hotkeys)
- [Browser and link routing](Browser-and-link-routing)
- [CLI reference](CLI-reference)
- [Hooks](Hooks)
- [Troubleshooting](Troubleshooting)
- [Publishing](Publishing)

## What a space controls

Notifications. Each space declares whose notifications it will show, and can
vary that by time of day. In the work space you do not see personal messages.
In the personal space you can choose to see both during working hours and only
personal after six.

Links. Click a link anywhere and it opens in that space's browser profile. No
profile picker in between.

Accounts. Each space carries an email address and a set of assistant accounts,
readable by scripts through `omarchy-spaces get`.

Windows. Each space owns a range of real Hyprland workspaces, so the same
keystroke reaches different windows depending on the space. See
[Workspaces and windows](Workspaces-and-windows).

Appearance. A space can pin a theme, font, and background, applied on switch so
the active context is obvious. See [Appearance](Appearance).

## Configuration app

`omarchy-spaces-config` is a GTK4 editor for everything below. Reach it by
clicking the Spaces indicator in the bar and picking "Space settings", from
your launcher as "Omarchy Spaces", or by running the command. Editing
`spaces.json` by hand works equally well.

## Two files

Configuration lives at `~/.config/omarchy-spaces/spaces.json`. You edit this.

Active state lives at `~/.local/state/omarchy-spaces/active`. The system writes
this, you do not. Keeping them apart means your rules survive a switch and a
switch survives a config edit.

## Requirements

Omarchy 4.0.0 or newer, python3, and a Chromium-family browser if you want link
routing. Node is needed only to run the test suite.
