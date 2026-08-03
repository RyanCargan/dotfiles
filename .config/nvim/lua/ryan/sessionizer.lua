-- lua/ryan/sessionizer.lua
local wezterm = require("wezterm")

local M = {}

function M.get_dirs()
    local cmd = "zsh -ic 'z -l 2>/dev/null'"
    local handle = io.popen(cmd)
    if not handle then
        vim.notify("Failed to run zsh -ic", vim.log.levels.WARN)
        return M.fallback_dirs()
    end

    local result = handle:read("*a")
    handle:close()

    local dirs = {}
    for line in result:gmatch("[^\n]+") do
        local score, path = line:match("^(%d+)%s+(.+)$")
        if score and path and path:match("^/") then
            table.insert(dirs, path)
        end
    end

    if #dirs == 0 then
        vim.notify("z.lua returned no valid dirs, using fallback", vim.log.levels.WARN)
        return M.fallback_dirs()
    end

    return dirs
end

function M.fallback_dirs()
    local home = os.getenv("HOME") or "~"
    local find_cmd = string.format("find %s -maxdepth 4 -type d -name .git -prune 2>/dev/null | sed 's|/.git$||'", home)
    local handle = io.popen(find_cmd)
    if not handle then return {} end
    local result = handle:read("*a")
    handle:close()
    local dirs = {}
    for line in result:gmatch("[^\n]+") do
        table.insert(dirs, line)
    end
    return dirs
end

function M.pick_and_switch()
    local dirs = M.get_dirs()
    if #dirs == 0 then
        vim.notify("No directories found", vim.log.levels.ERROR)
        return
    end

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

function M.open_workspace(dir)
    local workspace_name = dir:match("([^/]+)$") or dir

    local panes = wezterm.list_panes() or {}
    local found = false
    for _, pane in ipairs(panes) do
        if pane.workspace == workspace_name then
            found = true
            break
        end
    end

    if found then
        wezterm.exec_sync({ "wezterm", "cli", "switch-workspace", workspace_name })
    else
        wezterm.spawn(vim.env.SHELL or "zsh", {
            new_window = true,
            workspace = workspace_name,
            cwd = dir,
        })
        vim.notify("Opened workspace: " .. workspace_name, vim.log.levels.INFO)
    end
end

function M.switch_workspace()
    local panes = wezterm.list_panes() or {}
    local workspaces = {}
    local seen = {}
    for _, pane in ipairs(panes) do
        if pane.workspace and not seen[pane.workspace] then
            seen[pane.workspace] = true
            table.insert(workspaces, pane.workspace)
        end
    end

    if #workspaces == 0 then
        vim.notify("No workspaces found", vim.log.levels.WARN)
        return
    end

    vim.ui.select(workspaces, {
        prompt = "Switch to workspace:",
    }, function(choice)
        if not choice then return end
        wezterm.exec_sync({ "wezterm", "cli", "switch-workspace", choice })
        vim.notify("Switched to workspace: " .. choice, vim.log.levels.INFO)
    end)
end

return M
