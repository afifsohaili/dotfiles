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

-- Rebind SUPER+SHIFT+P (Omarchy default: Google Photos) to Pen.dev.
hl.unbind("SUPER + SHIFT + P")
o.bind("SUPER + SHIFT + P", "Pen", { launch = "pen --no-sandbox", focus = "^Pen$" })

-- Rebind SUPER+SHIFT+C (Omarchy default: Hey Calendar) to the browser (Chrome).
hl.unbind("SUPER + SHIFT + C")
o.bind("SUPER + SHIFT + C", "Browser", { omarchy = "browser" })

-- Drop the duplicate Browser binding on SUPER+SHIFT+B (SUPER+SHIFT+RETURN remains).
hl.unbind("SUPER + SHIFT + B")

-- Rebind SUPER+SHIFT+G (Omarchy default: Signal) to Gmail.
hl.unbind("SUPER + SHIFT + G")
o.bind("SUPER + SHIFT + G", "Gmail", { webapp = "https://mail.google.com/", focus = true })

-- Screenshot on ALT+SHIFT+4 (same smart flow as PRINT).
o.bind("ALT + SHIFT + 4", "Screenshot", "omarchy-capture-screenshot")
