# Editing a space

## Where to edit

```bash
$EDITOR ~/.config/omarchy-spaces/spaces.json
```

Middle click the bar widget cycles to the next space. There is no in-shell
editor yet, so the JSON file is the way.

Save and the running shell reloads on its own. The bar widget, the policy, and
the CLI all read the same file, so they never disagree.

## Always validate after an edit

```bash
omarchy-spaces validate
```

It reports four kinds of problem.

Duplicate space ids.

An `allowFrom` entry naming a space that does not exist. This is the common
one, usually a typo or a leftover after a rename.

Schedule windows that leave part of the day uncovered. Those minutes fall back
to the baseline `allowFrom`, which is legal but rarely what you meant.

Overlapping windows. The first match wins, so the later window silently never
applies.

## Renaming a space

The `id` is referenced in three other places. Change all of them together:

1. Other spaces' `notifications.allowFrom` arrays.
2. Your hotkeys in `~/.config/hypr/bindings.lua`.
3. The menu block, refreshed with `omarchy-spaces install-menu`.

The active state file may still hold the old id. It falls back to the config's
`activeSpace` if the stored id no longer resolves, so nothing breaks, but set
it explicitly:

```bash
omarchy-spaces switch <new-id>
```

## Deleting a space

Remove the object from `spaces`, then remove every `allowFrom` reference to it.
`validate` will point at any you missed. Refresh the menu afterwards.

## Changing the default space

`activeSpace` at the top level of the config decides which space is active when
no state file exists yet. It does not override a running session.

## Editing safely

The file is read on every change, so a half saved file can produce a parse
error. Nothing is lost when that happens. The service keeps the last good
config and logs the error:

```bash
journalctl --user --since '-5min' | grep omarchy-spaces
```

Fix the JSON and it reloads.
