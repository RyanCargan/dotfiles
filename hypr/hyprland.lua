-- ============================================================
--  MAIN SETTINGS TABLE (will be returned at the end)
-- ============================================================

local config = {
    monitor = ", preferred, auto, 1",

    vars = {
        terminal = "tilix",
        fileManager = "thunar",
        menu = "rofi -show drun",
        mainMod = "SUPER",
    },

    exec_once = {
        "waybar",
        "nm-applet --indicator",
        "/run/current-system/sw/libexec/polkit-gnome-authentication-agent-1",
    },

    env = {
        XCURSOR_SIZE = 24,
        HYPRCURSOR_SIZE = 24,
    },

    general = {
        gaps_in = 5,
        gaps_out = 20,
        border_size = 2,
        col_active_border = "rgba(33ccffee) rgba(00ff99ee) 45deg",
        col_inactive_border = "rgba(595959aa)",
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

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

    animations = {
        enabled = true,
        bezier = {
            { "easeOutQuint", 0.23, 1, 0.32, 1 },
            { "easeInOutCubic", 0.65, 0.05, 0.36, 1 },
            { "linear", 0, 0, 1, 1 },
            { "almostLinear", 0.5, 0.5, 0.75, 1.0 },
            { "quick", 0.15, 0, 0.1, 1 },
        },
        animation = {
            { "global", 1, 10, "default" },
            { "border", 1, 5.39, "easeOutQuint" },
            { "windows", 1, 4.79, "easeOutQuint" },
            { "windowsIn", 1, 4.1, "easeOutQuint", "popin 87%" },
            { "windowsOut", 1, 1.49, "linear", "popin 87%" },
            { "fadeIn", 1, 1.73, "almostLinear" },
            { "fadeOut", 1, 1.46, "almostLinear" },
            { "fade", 1, 3.03, "quick" },
            { "layers", 1, 3.81, "easeOutQuint" },
            { "layersIn", 1, 4, "easeOutQuint", "fade" },
            { "layersOut", 1, 1.5, "linear", "fade" },
            { "fadeLayersIn", 1, 1.79, "almostLinear" },
            { "fadeLayersOut", 1, 1.39, "almostLinear" },
            { "workspaces", 1, 1.94, "almostLinear", "fade" },
            { "workspacesIn", 1, 1.21, "almostLinear", "fade" },
            { "workspacesOut", 1, 1.94, "almostLinear", "fade" },
        },
    },

    dwindle = { preserve_split = true },
    master = { new_status = "master" },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
    },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = { natural_scroll = false },
    },
}

-- ============================================================
--  KEYBINDS (hl.bind) – must come BEFORE the final `return`
-- ============================================================

local mainMod = "SUPER"

-- Main application shortcuts
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("tilix"))
hl.bind(mainMod .. " + C", hl.dsp.killactive())
hl.bind(mainMod .. " + L", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mainMod .. " + P", hl.dsp.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layoutmsg("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.fullscreen(0))
hl.bind(mainMod .. " + G", hl.dsp.fullscreen(1))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("hyprctl dismissnotify"))

-- Focus movement
hl.bind(mainMod .. " + left", hl.dsp.movefocus("l"))
hl.bind(mainMod .. " + right", hl.dsp.movefocus("r"))
hl.bind(mainMod .. " + up", hl.dsp.movefocus("u"))
hl.bind(mainMod .. " + down", hl.dsp.movefocus("d"))

-- Switch to workspace 1-9, and 0 for 10
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.workspace(i))
end
hl.bind(mainMod .. " + 0", hl.dsp.workspace(10))

-- Move window to workspace 1-9, and 0 for 10
for i = 1, 9 do
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.movetoworkspace(i))
end
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.movetoworkspace(10))

-- Special workspace (magic)
hl.bind(mainMod .. " + S", hl.dsp.togglespecialworkspace("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.movetoworkspace("special:magic"))

-- Mouse wheel workspace switching
hl.bind(mainMod .. " + mouse_down", hl.dsp.workspace("e+1"))
hl.bind(mainMod .. " + mouse_up", hl.dsp.workspace("e-1"))

-- Move / resize window with mouse (bindm)
hl.bind(mainMod .. " + mouse:272", hl.dsp.movewindow())
hl.bind(mainMod .. " + mouse:273", hl.dsp.resizewindow())

-- Volume keys (release + locked)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { release = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { release = true, locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { release = true, locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { release = true, locked = true })

-- Brightness keys (release + locked)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { release = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { release = true, locked = true })

-- Media keys (locked only, no release)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- ============================================================
--  WINDOW RULES (hl.window_rule)
-- ============================================================

-- Firefox Picture‑in‑Picture: all five rules
hl.window_rule({
    match = { class = "^(firefox-nightly)$", title = "^(Picture-in-Picture)$" },
    float = true,
})
hl.window_rule({
    match = { class = "^(firefox-nightly)$", title = "^(Picture-in-Picture)$" },
    pin = true,
})
hl.window_rule({
    match = { class = "^(firefox-nightly)$", title = "^(Picture-in-Picture)$" },
    keep_aspect_ratio = true,
})
hl.window_rule({
    match = { class = "^(firefox-nightly)$", title = "^(Picture-in-Picture)$" },
    size = "25% 25%",
})
hl.window_rule({
    match = { class = "^(firefox-nightly)$", title = "^(Picture-in-Picture)$" },
    move = "74% 7%",
})

-- Suppress maximize events for all windows
hl.window_rule({
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- No focus for specific XWayland floating windows
hl.window_rule({
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
--  FINAL RETURN – MUST BE THE LAST STATEMENT
-- ============================================================

return config
