-- Omarchy Spaces keybindings.
--
-- Copy into ~/.config/hypr/bindings.lua, or require this file from it.
-- Check for conflicts first: omarchy menu keybindings --print

-- Space switching
o.bind("SUPER + ALT + O", "Spaces picker", "omarchy menu summon spaces")
o.bind("SUPER + ALT + N", "Next space", "omarchy-spaces next")
o.bind("SUPER + ALT + I", "Space status",
  "bash -lc 'omarchy-notification-send \"$(omarchy-spaces status)\"'")
o.bind("SUPER + ALT + P", "Space: Personal", "omarchy-spaces switch personal")
o.bind("SUPER + ALT + W", "Space: HiScale", "omarchy-spaces switch work")

-- Workspaces, scoped to the active space.
--
-- These replace Omarchy's SUPER+1..0 and SUPER+SHIFT+1..0. The number is a
-- slot within the active space's range, not a real workspace id, so SUPER+2
-- means real workspace 2 in personal and real workspace 12 in work. That is
-- what keeps the higher ranges reachable without inventing new keys.
for i = 1, 10 do
  local key = "code:" .. tostring(i + 9)
  hl.unbind("SUPER + " .. key)
  hl.unbind("SUPER + SHIFT + " .. key)
  o.bind("SUPER + " .. key, "Workspace " .. i .. " (this space)",
    "omarchy-spaces workspace " .. i)
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. i .. " (this space)",
    "omarchy-spaces move-to-workspace " .. i)
end

-- Send the focused window to another space. It leaves silently, so you stay
-- where you are. Add --follow to go with it.
o.bind("SUPER + ALT + SHIFT + P", "Send window to Personal",
  "omarchy-spaces move-to-space personal")
o.bind("SUPER + ALT + SHIFT + W", "Send window to HiScale",
  "omarchy-spaces move-to-space work")
