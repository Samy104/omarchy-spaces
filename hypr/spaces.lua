-- Omarchy Spaces keybindings.
--
-- Copy the bindings you want into ~/.config/hypr/bindings.lua, or require this
-- file from it. Every default here uses SUPER + ALT, which Omarchy 4 leaves
-- mostly free apart from window grouping.
--
-- Check for conflicts before adding: omarchy menu keybindings --print

-- Cycle through spaces
o.bind("SUPER + ALT + SPACE", "Next space", "omarchy-spaces next")
o.bind("SUPER + ALT + SHIFT + SPACE", "Previous space", "omarchy-spaces prev")

-- Jump straight to a space by id
o.bind("SUPER + ALT + P", "Space: personal", "omarchy-spaces switch personal")
o.bind("SUPER + ALT + W", "Space: work", "omarchy-spaces switch work")

-- Show the current policy as a notification
o.bind("SUPER + ALT + I", "Space status", "bash -lc 'omarchy-notification-send -g 󰃜 \"$(omarchy-spaces status)\"'")
