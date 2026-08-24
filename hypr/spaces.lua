-- Omarchy Spaces keybindings.
--
-- Copy the ones you want into ~/.config/hypr/bindings.lua. Every default here
-- uses SUPER + ALT, which Omarchy 4 leaves largely free apart from window
-- grouping (arrows, TAB, G, S) and the Apps menu (SPACE).
--
-- Check before adding: omarchy menu keybindings --print

o.bind("SUPER + ALT + O", "Spaces picker", "omarchy menu summon spaces")
o.bind("SUPER + ALT + N", "Next space", "omarchy-spaces next")
o.bind("SUPER + ALT + I", "Space status",
  "bash -lc 'omarchy-notification-send \"$(omarchy-spaces status)\"'")

-- One key per space. Rename these to match your own space ids.
o.bind("SUPER + ALT + P", "Space: Personal", "omarchy-spaces switch personal")
o.bind("SUPER + ALT + W", "Space: HiScale", "omarchy-spaces switch work")
