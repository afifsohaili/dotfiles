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

-- Rebind SUPER+SHIFT+O (Omarchy default: Obsidian) to the opencode picker.
-- `oc-project` builds the directory list, focuses an already-open directory,
-- or launches a new `oc` window. It resolves everything itself and does not
-- depend on the launch cwd.
hl.unbind("SUPER + SHIFT + O")
o.bind("SUPER + SHIFT + O", "Opencode", "oc-project")

-- Screenshot on ALT+SHIFT+4 (same smart flow as PRINT).
o.bind("ALT + SHIFT + 4", "Screenshot", "omarchy-capture-screenshot")
