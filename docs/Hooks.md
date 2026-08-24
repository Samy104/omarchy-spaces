# Hooks

Any executable in `~/.config/omarchy-spaces/hooks/` runs on every space switch,
in filename order.

## Environment

| Variable | Value |
|---|---|
| `OMARCHY_SPACE` | The space being switched to |
| `OMARCHY_SPACE_PREVIOUS` | The space being left, empty on first switch |

The rest of your environment is inherited.

## Example, git identity

`~/.config/omarchy-spaces/hooks/10-git-identity`:

```bash
#!/usr/bin/env bash
email=$(omarchy-spaces get email)
[ -n "$email" ] && git config --global user.email "$email"
```

```bash
chmod +x ~/.config/omarchy-spaces/hooks/10-git-identity
```

## Example, SSH config

```bash
#!/usr/bin/env bash
ln -sf "$HOME/.ssh/config.$OMARCHY_SPACE" "$HOME/.ssh/config"
```

## Example, only on leaving a space

```bash
#!/usr/bin/env bash
[ "$OMARCHY_SPACE_PREVIOUS" = "work" ] || exit 0
tailscale down
```

## Rules

Hooks run with a 15 second timeout each. One that hangs is killed and the
switch continues.

Output is captured and discarded. Log to a file if you need to see it.

A failing hook does not abort the switch. Nothing should be able to strand you
between spaces.

Numeric prefixes control order, the same convention as `/etc/cron.d`.

## Debugging

Run it by hand with the environment set:

```bash
OMARCHY_SPACE=work OMARCHY_SPACE_PREVIOUS=personal \
  ~/.config/omarchy-spaces/hooks/10-git-identity
```
