# CLI reference

```
omarchy-spaces list                 every space, active one marked
omarchy-spaces current [--json]     the active space id
omarchy-spaces switch <id>          make a space active
omarchy-spaces next | prev          cycle
omarchy-spaces status [--json]      the policy in effect right now
omarchy-spaces open <url>           open a url in the active space's browser
omarchy-spaces which [url]          print the argv `open` would run
omarchy-spaces get <field>          read a field off the active space
omarchy-spaces init [--force]       write a starter config
omarchy-spaces validate             check for gaps, overlaps, bad references
omarchy-spaces install-menu         add the space rows to the Omarchy menu
omarchy-spaces remove-menu          take them back out
omarchy-spaces menu                 print the rows without writing anything

omarchy-spaces workspace <n>            go to slot n of the active space
omarchy-spaces move-to-workspace <n>    move the focused window to slot n
omarchy-spaces move-to-space <id> [n]   send the focused window to another space
omarchy-spaces windows                  list open windows grouped by space

omarchy-spaces appearance show          pinned look vs the live one
omarchy-spaces appearance capture       save the current theme, font, background
omarchy-spaces appearance apply         re-apply the pinned look
omarchy-spaces appearance clear         stop pinning a look
```

## get

Reads any top level field off the active space, plus assistant accounts through
a dotted key.

```bash
omarchy-spaces get email            # you@company.com
omarchy-spaces get name             # HiScale
omarchy-spaces get assistant.codex  # work
```

Unknown fields print an empty line rather than failing, so it is safe in a
shell prompt.

## Scripting

```bash
# git identity that follows the space
git config user.email "$(omarchy-spaces get email)"

# only run something in one space
[ "$(omarchy-spaces current)" = "work" ] && ./deploy.sh

# is anything muted right now
omarchy-spaces status --json | python3 -c "
import json,sys
p=json.load(sys.stdin)['policy']
print('muted' if not p['allowFrom'] and not p['allowUnassigned'] else 'allowing ' + ', '.join(p['allowFrom']))
"
```

## Exit codes

`0` on success. `1` on a usage error or a failed `validate`. `2` when the config
is missing or unparseable.

`validate` returning 1 means it printed warnings, not that the config is
unusable.

## Why python

The CLI is python3 rather than node because Hyprland keybindings and desktop
handlers run with a minimal PATH. python3 is always present on Omarchy, a mise
managed node may not resolve.

The policy rules therefore exist twice, in `bin/omarchy-spaces` and in
`SpacesLogic.js` for the shell plugin. `test/parity.sh` runs both across every
minute of the day for every space and fails if a single decision differs.
