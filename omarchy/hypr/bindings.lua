-- Personal Hyprland keybinding overrides.
-- Symlinked to ~/.config/hypr/bindings.lua; loaded last, after Omarchy defaults.
--
-- See current bindings and descriptions:
--   omarchy menu keybindings --print
--
-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false
--
-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Rebind SUPER+SHIFT+A (Omarchy default: ChatGPT web app) to herdr.
hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + A", "Herdr", "omarchy-launch-terminal herdr")

-- Rebind SUPER+SHIFT+O (Omarchy default: Obsidian) to a shared opencode client.
-- Launches have no project cwd, so pin the projects root; a bare `oc` run from
-- inside a project targets that project instead.
hl.unbind("SUPER + SHIFT + O")
o.bind("SUPER + SHIFT + O", "Opencode", "omarchy-launch-tui --app-id=org.omarchy.opencode oc \"$HOME/Projects\"")

-- Screenshot on ALT+SHIFT+4 (same smart flow as PRINT).
o.bind("ALT + SHIFT + 4", "Screenshot", "omarchy-capture-screenshot")
