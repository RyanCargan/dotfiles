return {
    -- mason must be a top-level spec with `opts = {}` so lazy.nvim auto-runs
    -- `require('mason').setup(opts)` and registers the :Mason / :MasonInstall
    -- user commands. Buried as a dependency of nvim-lspconfig, the setup
    -- call inside lspconfig's `config = function()` only fires after
    -- lspconfig's lazy trigger; mason v2.x's command registration gets
    -- skipped on first :Mason, so the command is "not defined" until
    -- the editor is restarted. Top-level opts avoids that race.
    {
        "williamboman/mason.nvim",
        opts = {
            -- mason.nvim's own ensure_installed: tools that aren't LSPs
            -- (formatters, linters, DAP adapters). LSPs go in the
            -- mason-lspconfig spec below.
            ensure_installed = {
                "prettier",
                "stylua",
                "ruff",
                "shfmt",
                "nixfmt",
            },
        },
    },
    {
        "williamboman/mason-lspconfig.nvim",
        opts = {
            ensure_installed = {
                "lua_ls",
                "zls",
                "html",
                "cssls",
                "marksman",
                "sqlls",
                "bashls",
                "wgsl_analyzer",
                "vtsls",
                "pyright",
                -- clangd is NOT mason-managed: comes from the system closure
                -- via clang-tools (shared/dev-pkgs.nix tools.cppLlvmRuntime),
                -- which also provides clang-format (conform formatter) and
                -- clang-tidy. nixpkgs has no standalone clangd package.
                -- "rust_analyzer" -- commented out (heavy ~500MB); keep rust parser for reading without server
                -- nixd is provided via devPkgs (shared/dev-pkgs.nix), not mason — see nix.lua
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "stevearc/conform.nvim",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "hrsh7th/nvim-cmp",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "j-hui/fidget.nvim",
        },

        config = function()
            -- nvim-lspconfig 2.x ships new-style server defs at
            --   <lazy>/nvim-lspconfig/lsp/<name>.lua
            -- These files are NOT Lua modules (no `return`); they're config tables
            -- intended to be loaded via dofile/loadfile, then passed to
            -- `vim.lsp.config(name, def)`. mason-lspconfig's automatic_enable
            -- does this for Mason-installed servers (see
            -- mason-lspconfig/features/automatic_enable.lua:42-47); for nix-managed
            -- servers (clangd, nixd) we replicate the bridge here.
            local function load_lspconfig_def(name)
                local path = vim.fn.stdpath("data")
                    .. "/lazy/nvim-lspconfig/lsp/" .. name .. ".lua"
                if vim.fn.filereadable(path) == 0 then return nil end
                local chunk, err = loadfile(path)
                if not chunk then
                    vim.notify("lspconfig def load failed for " .. name .. ": " .. err, vim.log.levels.WARN)
                    return nil
                end
                return chunk()
            end

            require("conform").setup({
                formatters_by_ft = {
                    -- C/C++: clang-format from clang-tools (nix closure)
                    c = { "clang_format" },
                    cpp = { "clang_format" },
                    -- Python: ruff does formatting + import sorting + linting
                    python = { "ruff_format" },
                    -- Lua: stylua (consistent with lua_ls's defaultConfig)
                    lua = { "stylua" },
                    -- Web: prettier handles html/css/js/ts/json/md/yaml
                    javascript = { "prettier" },
                    typescript = { "prettier" },
                    javascriptreact = { "prettier" },
                    typescriptreact = { "prettier" },
                    json = { "prettier" },
                    html = { "prettier" },
                    css = { "prettier" },
                    markdown = { "prettier" },
                    yaml = { "prettier" },
                    -- Shells: shfmt works on bash + zsh; bashls handles the rest
                    sh = { "shfmt" },
                    bash = { "shfmt" },
                    zsh = { "shfmt" },
                    -- Nix: nixfmt (nixd isn't a formatter)
                    nix = { "nixfmt" },
                    -- SQL: sqlfluff would need DB config; skip for now
                    -- WGSL: naga doesn't have a stable formatter yet
                    -- Zig: zig fmt via the zig binary (system closure)
                },
                format_on_save = {
                    lsp_format = "fallback",
                },
            })
            local cmp = require('cmp')
            local cmp_lsp = require("cmp_nvim_lsp")
            local capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                cmp_lsp.default_capabilities())

            require("fidget").setup({})

            vim.lsp.config("*", {
                capabilities = capabilities,
            })

            -- nix-managed servers: load the new-style def from lspconfig's lsp/
            -- dir via loadfile (those files have no `return`, so require() can't
            -- load them) and merge our overrides.
            local function register_lspconfig_server(name, overrides)
                local def = load_lspconfig_def(name)
                if not def then
                    vim.notify("lspconfig def not found: " .. name, vim.log.levels.WARN)
                    return
                end
                vim.lsp.config(name, vim.tbl_deep_extend("force", def, overrides or {}))
            end

            -- clangd: nix closure (clang-tools). Override capabilities.
            register_lspconfig_server("clangd", { capabilities = capabilities })
            -- nixd: nix closure (devPkgs). Lspconfig doesn't ship a nixd def; hand-write.
            vim.lsp.config("nixd", {
                capabilities = capabilities,
                cmd = { "nixd" },
                filetypes = { "nix" },
                root_markers = { ".git", "flake.nix" },
                settings = {
                    nixd = {
                        formatting = { command = { "nixfmt" } },
                    },
                },
            })

            -- Hand-tuned defs for servers that need settings beyond what lspconfig ships.
            vim.lsp.config("zls", {
                capabilities = capabilities,
                cmd = { "zls" },
                filetypes = { "zig", "zir" },
                root_markers = { ".git", "build.zig", "zls.json" },
                settings = {
                    zls = {
                        enable_inlay_hints = true,
                        enable_snippets = true,
                        warn_style = true,
                    },
                },
            })

            vim.lsp.config("lua_ls", {
                capabilities = capabilities,
                filetypes = { "lua" },
                settings = {
                    Lua = {
                        runtime = { version = 'LuaJIT' },
                        diagnostics = { globals = { 'vim' } },
                        workspace = {
                            library = vim.api.nvim_get_runtime_file("", true),
                            checkThirdParty = false,
                        },
                        format = {
                            enable = true,
                            defaultConfig = {
                                indent_style = "space",
                                indent_size = "2",
                            }
                        },
                    }
                }
            })

            vim.lsp.enable({ "lua_ls", "zls", "clangd", "nixd", "html", "cssls", "marksman", "sqlls", "bashls", "wgsl_analyzer", "vtsls", "pyright" })
            vim.g.zig_fmt_parse_errors = 0
            vim.g.zig_fmt_autosave = 0

            local cmp_select = { behavior = cmp.SelectBehavior.Select }

            cmp.setup({
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                    ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
                    ["<C-Space>"] = cmp.mapping.complete(),
                }),
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = 'luasnip' },
                    { name = 'cmp_ai' },
                }, {
                    { name = 'buffer' },
                })
            })

            vim.diagnostic.config({
                float = {
                    focusable = false,
                    style = "minimal",
                    border = "rounded",
                    source = "always",
                    header = "",
                    prefix = "",
                },
            })
        end
    },
}
