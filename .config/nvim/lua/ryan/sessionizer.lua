local wezterm = require("wezterm")

local M = {}

-- Get all directories from z.lua history
function M.get_dirs()
    -- z -l lists all entries: "score  /path/to/dir"
    local handle = io.popen("z -l 2>/dev/null")
    if not handle then
        vim.notify("z.lua not found or not in PATH", vim.log.levels.ERROR)
        return {}
    end

    local result = handle:read("*a")
    handle:close()

    local dirs = {}
    for line in result:gmatch("[^\n]+") do
        -- Extract the path (after the score and spaces)
        local path = line:match("^%S+%s+(.+)$")
        if path then
            table.insert(dirs, path)
        end
    end
    return dirs
end

-- Present directories and switch/launch workspace
function M.pick_and_switch()
    local dirs = M.get_dirs()
    if #dirs == 0 then
        vim.notify("No directories found in z.lua history", vim.log.levels.WARN)
        return
    end

    -- Use Neovim's generic ui.select (works with Telescope/fzf-lua if installed)
    vim.ui.select(dirs, {
        prompt = "Select workspace directory:",
        format_item = function(item)
            local basename = item:match("([^/]+)$") or item
            return string.format("%s (%s)", basename, item)
        end,
    }, function(choice)
        if not choice then return end
        M.open_workspace(choice)
    end)
end

-- Switch to an existing workspace or create a new one
function M.open_workspace(dir)
    local workspace_name = dir:match("([^/]+)$") or dir  -- use basename as workspace name

    -- Check if a WezTerm window already uses this workspace name
    local windows = wezterm.list_windows() or {}
    local found = false
    for _, win in ipairs(windows) do
        if win.workspace == workspace_name then
            found = true
            break
        end
    end

    if found then
        -- Switch to existing workspace in the current window
        wezterm.exec_sync({ "wezterm", "cli", "switch-workspace", workspace_name })
    else
        -- Spawn a new window in a new workspace with the chosen directory as cwd
        wezterm.spawn(vim.env.SHELL or "zsh", {
            new_window = true,
            workspace = workspace_name,
            cwd = dir,
        })
        vim.notify("Opened workspace: " .. workspace_name, vim.log.levels.INFO)
    end
end

return M
