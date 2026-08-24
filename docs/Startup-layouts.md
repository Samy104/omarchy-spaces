# Startup layouts

A space can describe what each of its workspaces should contain, and open it on
demand or at login.

```
HiScale (work)  startup on
  slot 1  split
    [ ] Gmail        google-chrome-stable --profile-directory="Profile 1" --app=https://mail.google.com
    [ ] Calendar     google-chrome-stable --profile-directory="Profile 1" --app=https://calendar.google.com
  slot 4  stack
    [ ] Jira calendar view
    [ ] Jira project view
```

## Recording one

Arrange a workspace the way you want it, then:

```bash
omarchy-spaces startup capture
```

That reads the workspace you are on and records what is open. In the app, the
Startup section on a space has the same thing as "Capture this workspace".

Capture is best effort, and it is worth knowing where the effort runs out.

**Ordinary apps** are recovered exactly. `/proc/<pid>/cmdline` is the command
that started them.

**Browser app windows** are rebuilt. A window opened with `--app=<url>` carries
the host and the profile in its window class, so the command can be
reconstructed from it.

**Browser tabs cannot be recovered.** Every window of a browser shares one
process, so the command line describes the browser and says nothing about the
page. Those are recorded with a name and no command, listed as needing one, and
never launched until you fill it in. The fix is either to type the URL, or to
open the page as an app window in the first place:

```bash
google-chrome-stable --profile-directory="Profile 1" --app=https://mail.google.com
```

App windows also make the layout reproducible, since a plain tab has no stable
window class to match on.

## Side by side, or stacked

Each slot has an arrangement.

`split` tiles the windows, which is Hyprland's normal behaviour.

`stack` puts them in one window group. They occupy the same space and you
alternate with `SUPER + ALT + TAB`. This is the one to use when two views of the
same thing should share a workspace rather than halve it.

## Opening it

```bash
omarchy-spaces startup run              # the active space
omarchy-spaces startup run work         # a particular space
omarchy-spaces startup run work 3       # one slot
```

Running it twice does not open anything twice. Each entry can carry a `match`,
a window class, and an entry whose window is already on that slot is skipped.
Capture fills `match` in for you.

The Startup section also has a Run button per workspace.

## At login

Turn on "Open automatically at login" for a space, then apply your keybinds:

```bash
omarchy-spaces keybinds install
```

That adds one line to the managed Hyprland block:

```lua
o.exec_on_start("omarchy-spaces startup run --login")
```

It replays the layout of whichever space is active at login, and only if that
space asked for it. Off by default, because opening a dozen windows on login is
not something you should inherit from having recorded a layout once.

## Turning parts off

Every level has a switch, and they are all in the Startup section.

The whole layout, with `enabled`. One workspace, with the switch on its row.
One entry, with the switch beside it.

```bash
omarchy-spaces startup disable work      # the whole space
omarchy-spaces startup disable work 2    # one slot
omarchy-spaces startup forget work 2     # drop a slot entirely
omarchy-spaces startup forget work       # drop the lot
```

## Reordering

The up and down buttons on each workspace row move it in the list. Slots run in
list order, not numeric order, so a workspace you want opened first can be
first even if it is slot 4.

## Backup

Startup layouts live in `spaces.json` with everything else, so the existing
export and import cover them. Nothing extra to do.

```bash
omarchy-spaces export ~/spaces-backup.json
omarchy-spaces import ~/spaces-backup.json
```

## A worked example

Two spaces on the same machine, one layout each.

```
Personal (personal)  startup on
  slot 1  split    Claude Code    foot --app-id=org.omarchy.agent -e claude ...
  slot 2  split    T3 Code        t3code
  slot 3  split    Conductor      google-chrome-stable --profile-directory="Profile 1" --app=https://conductor...
  slot 4  split    YouTube Music  google-chrome-stable --profile-directory=Default --app=https://music.youtube.com

HiScale (work)  startup on
  slot 1  split    Gmail, Calendar        Chrome, work profile, as app windows
  slot 2  split    NetSuite
  slot 3  split    T3 Code, VSCode
  slot 4  stack    Jira calendar + project views
```

Three things worth copying from it.

**Music as an app window gives you a bar player for free.** Opening
`music.youtube.com` with `--app=` registers on MPRIS like any native player, so
Omarchy's own media widget picks it up. Enable it with
`omarchy plugin enable omarchy.media`. No separate plugin needed for a player
in the bar.

**A shared app for the player.** YouTube Music belongs in neither space, so it
is listed once in `defaults.apps` with `"shared": true`. Its notifications
always reach you and its window is never moved. See
[Apps and segmentation](Apps-and-segmentation).

**Two spaces can use different browser profiles for the same site.** The
`--profile-directory` in each command is what decides which account opens, and
it does not have to match the space's own browser setting.

## Inheritance

`defaults.startup` applies to any space that does not define its own, like
every other key. A space that sets `startup` replaces it whole, since arrays
replace rather than merge. See
[Defaults and inheritance](Defaults-and-inheritance).
