# The default space

Not everything deserves a place in a list. A default space owns every app no
space claims, so you only name the exceptions.

```json
{ "fallbackSpace": "personal" }
```

Now Slack belongs to work because work lists it, and everything else belongs to
personal without being written down anywhere. In the work space an unlisted
app's notifications are hidden, because work only allows work. In personal they
show.

Set it in the app under General, "Default space". The sidebar marks that space
`default` next to `active`.

## Precedence

1. A shared app belongs to nobody and always gets through. It never falls back.
2. A space that lists the app owns it.
3. Otherwise the default space owns it.
4. With no default space set, the app is unassigned and `allowUnassigned`
   decides.

Setting a default space makes `allowUnassigned` irrelevant, since nothing is
unassigned any more. The app disables that switch and says so rather than
leaving a control that quietly does nothing.

## Two different "defaults"

They are easy to confuse, so the app names them apart.

**Default space** owns unlisted apps. This is `fallbackSpace`.

**Startup space** is the space that is active on a fresh machine before
anything has been switched to. This is `activeSpace`, and it only matters once.

## Windows are a separate decision

Ownership decides notification routing. It does **not** move windows by
default.

```json
{ "fallbackPlacesWindows": true }
```

turns on a catch-all Hyprland rule that opens every unlisted app in the default
space. It is off by default, and deliberately so: it is far-reaching. Every
terminal, editor, and file manager you open while in work would land in
personal. That is occasionally what people want and usually not, so it is a
choice rather than a consequence.

The rule is emitted before the specific ones so a named app still wins:

```lua
o.window(".*", { workspace = "1 silent" })       -- catch-all, first
o.window("^(Slack)$", { workspace = "11 silent" })  -- overrides it
```

## Checking it

```bash
omarchy-spaces status
```

```
unlisted   owned by Personal, shown here
```

In the work space the same line reads `hidden here`.
