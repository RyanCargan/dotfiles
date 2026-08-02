return {
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

    binds = {
        -- Main
        { "$mainMod", "Q", "exec", "$terminal" },
        { "$mainMod", "C", "killactive" },
        { "$mainMod", "L", "exit" },
        { "$mainMod", "E", "exec", "$fileManager" },
        { "$mainMod", "V", "togglefloating" },
        { "$mainMod", "R", "exec", "$menu" },
        { "$mainMod", "P", "pseudo" },
        { "$mainMod", "J", "layoutmsg", "togglesplit" },
        { "$mainMod", "F", "fullscreen", 0 },
        { "$mainMod", "G", "fullscreen", 1 },
        { "$mainMod SHIFT", "S", "exec", 'grim -g "$(slurp)" - | swappy -f -' },
        { "$mainMod SHIFT", "W", "exec", "hyprctl dismissnotify" },
        
        -- Focus
        { "$mainMod", "left", "movefocus", "l" },
        { "$mainMod", "right", "movefocus", "r" },
        { "$mainMod", "up", "movefocus", "u" },
        { "$mainMod", "down", "movefocus", "d" },

        -- Workspaces (1-10)
        -- (Ideally expanded in a loop in your generator)
        { "$mainMod", "1", "workspace", 1 },
        { "$mainMod", "2", "workspace", 2 },
        -- ... [rest of workspaces omitted for brevity but you get the pattern]

        -- Special
        { "$mainMod", "S", "togglespecialworkspace", "magic" },
        { "$mainMod SHIFT", "S", "movetoworkspace", "special:magic" },
    },

    windowrules = {
        { "match:class ^(firefox-nightly)$, match:title ^(Picture-in-Picture)$, float on" },
        { "match:class .*, suppress_event maximize" },
    }
}
