return {
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        ft = { "markdown" },
        opts = {
            pipe_table = { enabled = false },
        },
        config = function(_, opts)
            require("render-markdown").setup(opts)
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "markdown",
                callback = function()
                    vim.opt_local.wrap = true
                    vim.opt_local.linebreak = true
                    vim.opt_local.breakindent = true
                end,
            })
        end,
    },
    {
        "ice345/markdown-table-wrap.nvim",
        ft = { "markdown" },
        opts = {},
        keys = {
            { "<leader>mr", "<cmd>MarkdownTableToggleReader<cr>", desc = "Toggle Markdown reader" },
        },
    },
}
