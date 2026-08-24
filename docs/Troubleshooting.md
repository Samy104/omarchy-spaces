# Troubleshooting

## Reading the log

The shell logs to the journal. Almost every question starts here:

```bash
journalctl --user --since '-10min' | grep -E 'omarchy-spaces|WARN scene'
```

## The bar widget is missing

Check it is enabled and placed:

```bash
omarchy plugin list | grep spaces
```

If it says `disabled`:

```bash
omarchy plugin enable io.github.samy104.omarchy-spaces
omarchy restart shell
```

The widget hides itself when it cannot reach the service or when the active
space has no name and no icon, so an invisible widget usually means the config
failed to load. Run `omarchy-spaces validate`.

## The bar does not follow a switch

Confirm the CLI and the shell disagree:

```bash
omarchy-spaces current
```

If the CLI is right and the bar is stale, the shell's file watcher missed the
change. Restart it:

```bash
omarchy restart shell
```

This was a real bug before 0.1.1. The CLI writes state by atomic rename, which
swaps the inode out from under a file watcher. The service now watches the
parent directory instead. If you see it on 0.1.1 or later, that is worth
reporting.

## Notifications are not being filtered

Check what the policy actually allows right now:

```bash
omarchy-spaces status
```

If `allowing` lists more than you expect, the wrong schedule window is
matching. Give each window a `label` and it shows up in this output.

If the policy looks right but a notification still gets through, the app is
probably not in any `apps` list, so it counts as unassigned. Check what name it
sends:

```bash
ls -t ~/.local/state/omarchy/notifications/history/*.json | head -1 | \
  xargs python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['app'])"
```

Critical notifications bypass filtering on purpose. Set `"criticalBypass": false`
at the top level to change that.

## Everything is muted and I did not expect it

```bash
omarchy-spaces status
```

A window with an empty `allowFrom` and `allowUnassigned` false mutes everything
and turns on Omarchy's do not disturb. Check whether an overnight window is
still matching, and remember windows wrap past midnight.

## Do not disturb will not turn off

The plugin only clears the flag if it set it. If you toggled it yourself, toggle
it back with SUPER + CTRL + COMMA.

## Links open in the wrong profile

```bash
omarchy-spaces which https://example.com
```

That prints the exact argv. If the profile is wrong, check the `browser.profile`
value against the real directory names, see
[Browser and link routing](Browser-and-link-routing).

If it prints `xdg-open`, the active space declares no browser.

If links bypass the router entirely:

```bash
xdg-settings get default-web-browser
```

It should say `omarchy-spaces-open.desktop`.

## Config changes do nothing

```bash
omarchy-spaces validate
journalctl --user --since '-5min' | grep 'config parse failed'
```

A JSON syntax error leaves the last good config in place and logs the failure.
Trailing commas are the usual culprit.

## The picker is empty or missing

```bash
omarchy-spaces install-menu
```

Re-run it after adding or renaming a space. The block is delimited, so running
it twice replaces rather than duplicates.

## A glyph shows as a box or a stray character

The codepoint is outside your Nerd Font. Pick another from
[nerdfonts.com/cheat-sheet](https://www.nerdfonts.com/cheat-sheet). Codepoints
above the basic plane are the ones most likely to fail.

## Starting over

```bash
omarchy-spaces init --force
```

That overwrites `spaces.json` with the starter config. Your active space is left
alone.

## Reporting a bug

Include the output of:

```bash
omarchy version
omarchy-spaces status --json
omarchy-spaces validate
journalctl --user --since '-10min' | grep -E 'omarchy-spaces|WARN scene'
```

Issues go to
[github.com/Samy104/omarchy-spaces/issues](https://github.com/Samy104/omarchy-spaces/issues).
