# Keybinds

Bindings live in the config and are written into a delimited block in
`~/.config/hypr/bindings.lua`. Owning a block rather than the file means your
own bindings survive, and applying again replaces rather than appends.

## From the app

The Keybinds page lists every binding. Click one and press the combination you
want. Escape cancels, Backspace clears it.

Three actions at the bottom:

**Check for conflicts** compares against everything Hyprland already has bound
and names what would clash.

**Write and reload** writes the block, runs `hyprctl reload`, and reports any
config errors rather than leaving you to find them.

**Remove the block** takes it back out and leaves Hyprland's own bindings alone.

## From the command line

```bash
omarchy-spaces keybinds show        # what the config asks for
omarchy-spaces keybinds conflicts   # check against Hyprland
omarchy-spaces keybinds install     # write it and reload
omarchy-spaces keybinds print       # print the Lua without writing
omarchy-spaces keybinds remove      # take the block out
```

## Defaults

| Action | Binding |
|---|---|
| Open the Spaces picker | SUPER + ALT + O |
| Next space | SUPER + ALT + N |
| Previous space | SUPER + ALT + SHIFT + N |
| Show the current policy | SUPER + ALT + I |
| Workspace slot 1 to 10 | SUPER + the number |
| Move window to slot 1 to 10 | SUPER + SHIFT + the number |
| Switch to a space | per space, for example SUPER + ALT + P |
| Send the window to a space | per space, for example SUPER + ALT + SHIFT + P |

## Prefixes

`workspacePrefix` and `moveWindowPrefix` are modifiers only. The number key is
appended by the generated Lua, which loops 1 to 10 and unbinds Omarchy's own
`SUPER+1..0` first.

The number is a slot within the active space, not a real workspace id. That is
what keeps the second space's range reachable without new keys. See
[Workspaces and windows](Workspaces-and-windows).

## In the config

```json
"keybinds": {
  "picker": "SUPER + ALT + O",
  "next": "SUPER + ALT + N",
  "prev": "SUPER + ALT + SHIFT + N",
  "status": "SUPER + ALT + I",
  "workspacePrefix": "SUPER",
  "moveWindowPrefix": "SUPER + SHIFT"
}
```

Per space:

```json
{ "id": "work", "keybind": "SUPER + ALT + W", "sendKeybind": "SUPER + ALT + SHIFT + W" }
```

Omit a key to leave that action unbound.

## If a reload fails

`keybinds install` prints `hyprctl configerrors` and exits non-zero rather than
reporting success. Your previous file is saved as `bindings.lua.bak`.
