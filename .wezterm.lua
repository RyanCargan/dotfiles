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

-- ============================================================
-- Smart-splits integration: seamless Ctrl+h/j/k/l navigation
-- between wezterm panes and nvim splits
-- ============================================================
local function is_vim(pane)
  return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = { h = "Left", j = "Down", k = "Up", l = "Right" }

local function split_nav(resize_or_move, key)
  return {
    key = key,
    mods = resize_or_move == "resize" and "META" or "CTRL",
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        win:perform_action({
          SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
        }, pane)
      else
        if resize_or_move == "resize" then
          win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
        else
          win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
        end
      end
    end),
  }
end

config.keys = config.keys or {}
-- Move between panes: Ctrl+h/j/k/l
for _, key in ipairs({ "h", "j", "k", "l" }) do
  table.insert(config.keys, split_nav("move", key))
end

-- Resize panes: Alt+h/j/k/l
for _, key in ipairs({ "h", "j", "k", "l" }) do
  table.insert(config.keys, split_nav("resize", key))
end

-- Tab navigation (explicit, matches defaults)
table.insert(config.keys, { key = "Tab", mods = "CTRL", action = wezterm.action.ActivateTabRelative(1) })
table.insert(config.keys, { key = "Tab", mods = "SHIFT|CTRL", action = wezterm.action.ActivateTabRelative(-1) })

-- Spawn new tab: Ctrl+Shift+t
table.insert(config.keys, { key = "t", mods = "CTRL|SHIFT", action = wezterm.action.SpawnTab("CurrentPaneDomain") })

-- Finally, return the configuration
return config
