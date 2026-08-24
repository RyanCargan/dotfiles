return {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        local api = require("nvim-tree.api")

        require("nvim-tree").setup({
            update_focused_file = {
                enable = true,
                update_cwd = false,
            },
            git = {
                enable = true,
            },
            view = {
                width = 30,
                side = "left",
            },
            on_attach = function(bufnr)
                local function opts(desc)
                    return {
                        desc = "nvim-tree: " .. desc,
                        buffer = bufnr,
                        noremap = true,
                        silent = true,
                        nowait = true,
                    }
                end

                api.config.mappings.default_on_attach(bufnr)

                -- gG: open Fugitive status for the file/dir under cursor
                vim.keymap.set("n", "gG", function()
                    local node = api.tree.get_node_under_cursor()
                    if node.type == "file" then
                        vim.cmd("tcd " .. vim.fn.fnamemodify(node.absolute_path, ":p:h"))
                    else
                        vim.cmd("tcd " .. node.absolute_path)
                    end
                    vim.cmd("Git")
                end, opts("Fugitive status for this repo"))
            end,
        })

        vim.keymap.set("n", "<leader>e", function()
            vim.cmd("NvimTreeToggle")
        end, { desc = "Toggle file explorer" })
    end,
}
