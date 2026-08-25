-- Consolidated hyprland.lua
-- Base: hyprconf2lua v1.4.0 output, corrected against hl.meta.lua stub and
-- cross-checked against the hyprlang2lua conversion.
--
-- Fixes applied on top of the raw autogen output:
--   1. SUPER+SHIFT+S was bound twice in the original .conf (screenshot AND
--      special:magic move). Screenshot moved to SUPER+SHIFT+G, plus dedicated
--      Print / SUPER+Print binds added as alternates. SHIFT+S is now solely
--      owned by the special-workspace move.
--   2. hyprconf2lua dropped `repeating = true` from all media/volume/
--      brightness binds -- restored so holding the key repeats the action,
--      matching Hyprland's own official example config.
--   3. hyprconf2lua collapsed SUPER+F and SUPER+G to the same zero-arg
--      hl.dsp.window.fullscreen() call, losing the fullscreen-vs-maximize
--      distinction from the original conf. Restored with explicit
--      mode/action fields (verify `mode` field name against your build).
--   4. hyprconf2lua's screenshot command had a malformed shell string
--      ("$(slurp)"-| swappy -f-) missing spaces before the pipe and the
--      final flag. Restored to the original's spacing.
--   5. hyprconf2lua emitted the 5 Firefox PiP window rules with `class`
--      silently dropped (demoted to a TODO comment) and with NO action
--      fields at all (float/pin/keep_aspect_ratio/size/move all missing),
--      so as generated the rule matched nothing usefully and did nothing.
--      Reconstructed as a single rule with the original match + all 5
--      action fields, combining hyprlang2lua's action-field data with
--      hyprconf2lua's class match.
--   6. hyprconf2lua's maximize-suppression rule stuffed the action
--      ("suppress_event maximize") into the `class` match field by mistake,
--      so it would never match a real window. Restored to a real class
--      wildcard match with the suppress_event action.

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

local terminal    = "wezterm"
local fileManager  = "thunar"
local menu         = "rofi -show drun"
local mainMod      = "SUPER"

hl.env("XCURSOR_SIZE", 24)
hl.env("HYPRCURSOR_SIZE", 24)

hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global",         enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",         enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",        enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",      enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",     enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",         enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",        enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",           enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",         enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",       enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",      enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",   enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut",  enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",     enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",   enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut",  enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 20,
        border_size = 2,
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
    },
})

hl.config({
    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },
})

hl.config({ animations = { enabled = true } })
hl.config({ dwindle = { preserve_split = true } })
hl.config({ master = { new_status = "master" } })
hl.config({ misc = { force_default_wallpaper = -1, disable_hyprland_logo = false } })
hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = { natural_scroll = false },
    },
})

-- ============================================================
--  KEYBINDS
-- ============================================================

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + L", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- FIX #3: distinct fullscreen vs maximize (verify `mode` field name for your build)
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + G", hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }))

-- FIX #1: SUPER+SHIFT+S no longer double-bound. Screenshot moved to
-- SUPER+SHIFT+G, plus Print-key alternates. FIX #4: corrected shell spacing.
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'))
hl.bind("Print", hl.dsp.exec_cmd('grim - | wl-copy'))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'))

hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("hyprctl dismissnotify"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- vim-style home row focus (additive — arrows still work)
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))

for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
end
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))

for i = 1, 9 do
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Special workspace (magic) -- sole owner of SHIFT+S now
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- FIX #2: repeating restored for volume/brightness (matches Hyprland's own example config)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Media keys: single-fire, no repeat (matches original `bindl`)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- ============================================================
--  WINDOW RULES
-- ============================================================

-- FIX #5: reconstructed. hyprconf2lua dropped the class match and all 5
-- action fields; hyprlang2lua kept both class+title match and all actions.
-- Combining the two here as a single consolidated rule.
hl.window_rule({
    name  = "firefox_pip",
    match = {
        class = "^(firefox-nightly)$",
        title = "^(Picture-in-Picture)$",
    },
    float = true,
    pin = true,
    keep_aspect_ratio = true,
    size = "25% 25%",
    move = "74% 7%",
})

-- FIX #6: reconstructed. hyprconf2lua put the action string into the
-- `class` match field by mistake, producing a rule that could never match.
hl.window_rule({
    name  = "suppress_maximize_all",
    match = {
        class = ".*",
    },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "no_focus_xwayland_float",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

-- ============================================================
--  STARTUP
-- ============================================================

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("/run/current-system/sw/libexec/polkit-gnome-authentication-agent-1")
end)
