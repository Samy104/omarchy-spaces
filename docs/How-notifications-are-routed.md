# How notifications are routed

## The decision, in order

When a notification arrives, four questions decide whether you see it.

**Is it critical?** Urgency 2 in the freedesktop spec. Critical notifications
bypass filtering entirely, because losing a low battery or disk full warning to
a context filter is a worse outcome than seeing one message from the wrong
space. Set `"criticalBypass": false` at the top level of the config to turn
this off.

**Which space owns it?** The sender's app name is matched against every space's
`apps` list, case insensitively, with a trailing `.desktop` stripped. The first
space that claims it owns it. An app claimed by nobody is unassigned.

**What does the policy allow right now?** The active space's schedule is checked
against the wall clock. The first window that contains the current minute wins.
If no window matches, the space's baseline `notifications.allowFrom` applies.

**Is the owner in that list?** If yes, the notification shows. If the app is
unassigned, `allowUnassigned` decides instead.

## Schedule windows

```json
"schedule": [
  { "from": "08:00", "to": "17:00", "allowFrom": ["personal", "work"] },
  { "from": "17:00", "to": "22:00", "allowFrom": ["personal"] },
  { "from": "22:00", "to": "08:00", "allowFrom": [], "allowUnassigned": false }
]
```

That reads as: everything during working hours, personal only in the evening,
silent overnight.

The end bound is exclusive. `08:00 to 17:00` covers 08:00 through 16:59, so
adjacent windows never both match and you do not need gaps between them.

Windows may wrap past midnight. `22:00 to 08:00` is one window covering the
late evening and the early morning, not two.

Order matters. The first matching window wins, so keep them non overlapping.
`omarchy-spaces validate` flags overlaps and gaps.

`label` is optional and shows up in `omarchy-spaces status`, which makes it much
easier to tell which rule is firing.

## Seeing the current policy

```bash
omarchy-spaces status
```

```
space      Personal (personal)
email      you@example.com
browser    brave profile=Default
time       19:42
window     17:00 to 22:00  Evening, personal only
allowing   personal
unassigned shown
```

`omarchy-spaces status --json` gives the same thing for scripts.

## The bar indicator

The bar widget appends a mark when filtering is active.

No mark means everything currently reaches you.

A hollow circle means at least one space is blocked, but not everything.

A filled circle means the policy blocks everything. The widget also switches to
the urgent color.

## Nothing is deleted

A blocked notification is not thrown away. Omarchy's notification service still
receives it, writes it to history, and this plugin removes the popup afterwards.
Switch back to the space that owns it and the message is waiting in history.

The consequence worth knowing is that filtering is about interruption, not
secrecy. Anyone reading your notification history sees everything regardless of
which space was active.

## Why post filtering

This plugin does not replace Omarchy's notification daemon. It lets
`omarchy.notifications` accept everything, then removes the popups the policy
blocks.

That choice buys three things. History stays complete. The stock do not disturb
toggle keeps working, because when a policy blocks everything the service
mirrors that into the built in flag. And Omarchy keeps ownership of the D-Bus
name, so history, images, actions, and the popup lifecycle keep working when
Omarchy changes them.

The one caveat is a blocked popup may flash for a frame before removal on a
loaded system.

## Interaction with manual do not disturb

When a policy blocks everything, the plugin turns on Omarchy's do not disturb
flag so the normal bar icon tells the truth. It only turns it off again if it
was the one that turned it on. Toggling do not disturb yourself is never undone
by a schedule boundary.
