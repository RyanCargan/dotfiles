return {

    {
      "mrjones2014/smart-splits.nvim",
      lazy = false,
      config = function()
        local smart = require("smart-splits")

        -- Smart splits navigation (replaces toggleterm floating terminal)
        -- Ctrl+h/j/k/l navigates between nvim splits and wezterm panes
        vim.keymap.set("n", "<C-h>", smart.move_cursor_left, { desc = "Smart split left" })
        vim.keymap.set("n", "<C-j>", smart.move_cursor_down, { desc = "Smart split down" })
        vim.keymap.set("n", "<C-k>", smart.move_cursor_up, { desc = "Smart split up" })
        vim.keymap.set("n", "<C-l>", smart.move_cursor_right, { desc = "Smart split right" })

        -- Resize splits with Ctrl+Shift+h/j/k/l
        vim.keymap.set("n", "<C-S-h>", smart.resize_left, { desc = "Resize left" })
        vim.keymap.set("n", "<C-S-j>", smart.resize_down, { desc = "Resize down" })
        vim.keymap.set("n", "<C-S-k>", smart.resize_up, { desc = "Resize up" })
        vim.keymap.set("n", "<C-S-l>", smart.resize_right, { desc = "Resize right" })

        -- Toggle between previous split and current
        vim.keymap.set("n", "<C-\\>", smart.move_cursor_previous, { desc = "Toggle previous split" })

        -- Terminal split functionality (nvim-internal, not wezterm panes)
        local function open_term(dir)
          if dir == "auto" then
            local ratio = vim.o.columns / math.max(vim.o.lines, 1)
            dir = ratio > 1.6 and "v" or "h"
          end
          if dir == "v" then
            vim.cmd("vsplit")
          elseif dir == "h" then
            vim.cmd("split")
          end
          vim.cmd("terminal")
          vim.cmd("startinsert")
        end

        local function smart_rebalance()
          local layout = vim.fn.winlayout()
          local function needs_flip(node, ratio)
            if node[1] == "leaf" then return false end
            local want = ratio > 1.6 and "col" or "row"
            return node[1] ~= want
          end
          local ratio = vim.o.columns / math.max(vim.o.lines, 1)
          if needs_flip(layout, ratio) then
            vim.cmd("wincmd =")
            vim.notify(string.format("rebalance %s (ratio %.2f)", ratio > 1.6 and "vsplit" or "split", ratio))
          else
            vim.notify("layout already optimal")
          end
        end

        vim.keymap.set("n", "<leader>tt", function() open_term("v") end, { desc = "Terminal vsplit" })
        vim.keymap.set("n", "<leader>ts", function() open_term("h") end, { desc = "Terminal split" })
        vim.keymap.set("n", "<leader>to", function() open_term("o") end, { desc = "Terminal here" })
        vim.keymap.set("n", "<leader>ta", function() open_term("auto") end, { desc = "Terminal auto axis" })
        vim.keymap.set("n", "<leader>ar", smart_rebalance, { desc = "Smart rebalance" })

        vim.api.nvim_create_autocmd("TermOpen", {
          callback = function()
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false
            vim.opt_local.signcolumn = "no"
          end,
        })
        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Terminal normal mode" })
      end,
    },

}
