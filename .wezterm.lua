-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- or, changing the font size and color scheme.
config.font_size = 10
config.color_scheme = 'AdventureTime'

-- Enable transparency
config.window_background_opacity = 0.85   -- <-- add this line

-- Enable auto-refresh
automatically_reload_config = true

-- Scrollbar
config.enable_scroll_bar = true
-- Hide the scrollbar when there is no scrollback or alternate screen is active
wezterm.on("update-status", function(window, pane)
local overrides = window:get_config_overrides() or {}
local dimensions = pane:get_dimensions()

overrides.enable_scroll_bar = dimensions.scrollback_rows > dimensions.viewport_rows and not pane:is_alt_screen_active()

window:set_config_overrides(overrides)
end)

-- Finally, return the configuration to wezterm:
return config
