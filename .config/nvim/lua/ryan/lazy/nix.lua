return {
    -- nixd is registered in lsp.lua (shared nvim-lspconfig config)
    -- conform nix formatter also configured there
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                nix = { "nixfmt" },
            },
        },
    },
}
