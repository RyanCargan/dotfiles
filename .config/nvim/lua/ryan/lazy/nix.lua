return {
    {
        "neovim/nvim-lspconfig",
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            vim.lsp.config("nixd", {
                capabilities = capabilities,
                cmd = { "nixd" },
                filetypes = { "nix" },
                root_markers = { "flake.nix", ".git" },
                settings = {
                    nixd = {
                        nixpkgs = {
                            expr = "import <nixpkgs> {}",
                        },
                        options = {
                            nixos = {
                                expr = '(builtins.getFlake "/home/ryan/Code/Repos/lab/submodules/dotfiles").nixosConfigurations.nixos.options',
                            },
                        },
                    },
                },
            })
            vim.lsp.enable("nixd")
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                nix = { "nixfmt" },
            },
        },
    },
}
