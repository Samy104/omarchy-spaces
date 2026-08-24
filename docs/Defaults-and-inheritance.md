# Defaults and inheritance

A top-level `defaults` block supplies values for every space. A space overrides
what it sets and inherits the rest, so a shared browser, schedule, or workspace
count is written once instead of repeated per space.

```json
{
  "defaults": {
    "browser": { "command": "brave" },
    "workspaces": { "count": 10 },
    "notifications": {
      "allowUnassigned": false,
      "schedule": [
        { "from": "22:00", "to": "08:00", "allowFrom": [], "allowUnassigned": false }
      ]
    }
  },
  "spaces": [
    { "id": "personal", "browser": { "profile": "Default" } },
    { "id": "work", "browser": { "profile": "Profile 1" } }
  ]
}
```

Both spaces get Brave, the overnight silence, and ten slots. Each sets only its
own profile.

## The merge rules

Objects merge one key at a time, recursively. `personal` above ends up with
`browser.command` from defaults and `browser.profile` of its own.

Arrays and scalars are replaced whole. A space that sets `apps` replaces the
default list rather than adding to it. A half-inherited list is harder to reason
about than an explicit one, and appending has no obvious way to remove an entry.

Identity is never inherited. `id`, `name`, `icon`, and `color` belong to a
space, and putting them in `defaults` does nothing.

## Editing it

The Defaults page in the config app uses the same form as a space, minus the
identity fields. A space whose values come from defaults says so under its name
in the header.

## One thing to watch

`defaults.apps` reaches every space that does not define its own `apps`. If two
spaces both inherit it, both claim the same apps, and the first one in the list
wins. `omarchy-spaces validate` says so plainly:

```
warn: app 'shared' is claimed by personal and work; personal wins
```

That is usually a sign the app belongs in one space's own list rather than in
defaults.

## Turning it off

Delete the `defaults` block. Nothing else changes, and every space keeps
whatever it set explicitly.
