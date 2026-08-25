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
config.window_background_opacity = 0.85

-- Enable auto-refresh
config.automatically_reload_config = true

-- Scrollbar
config.enable_scroll_bar = true
config.colors = config.colors or {}
config.colors.scrollbar_thumb = '#888888'
-- Hide the scrollbar when the alternate screen is active (e.g., vim, less)
wezterm.on("update-status", function(window, pane)
  local overrides = window:get_config_overrides() or {}
  overrides.enable_scroll_bar = not pane:is_alt_screen_active()
  window:set_config_overrides(overrides)
end)

config.keys = config.keys or {}
-- Tab navigation (explicit, matches defaults)
table.insert(config.keys, { key = "Tab", mods = "CTRL", action = wezterm.action.ActivateTabRelative(1) })
table.insert(config.keys, { key = "Tab", mods = "SHIFT|CTRL", action = wezterm.action.ActivateTabRelative(-1) })

 -- Spawn new tab: Ctrl+Shift+t
table.insert(config.keys, { key = "t", mods = "CTRL|SHIFT", action = wezterm.action.SpawnTab("CurrentPaneDomain") })

-- Finally, return the configuration
return config
