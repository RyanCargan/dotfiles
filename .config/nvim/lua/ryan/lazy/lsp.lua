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
                "sqls",
                "bashls",
                "wgsl_analyzer",
                "vtsls",
                "pyright",
                -- clangd is NOT mason-managed: comes from the system closure
                -- via clang-tools (shared/dev-pkgs.nix tools.cppLlvmRuntime),
                -- which also provides clang-format (conform formatter) and
                -- clang-tidy. nixpkgs has no standalone clangd package.
                -- "rust_analyzer" -- commented out (heavy ~500MB); keep rust parser for reading without server
                -- nixd is provided via devPkgs (shared/dev-pkgs.nix), not mason -- see nix.lua
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

            -- Default caps for all servers.
            vim.lsp.config("*", {
                capabilities = capabilities,
            })

            -- Nix-managed servers: mason-lspconfig's automatic_enable only
            -- registers servers it installed via Mason. clangd and nixd come
            -- from the nix closure, so we register them by hand here using
            -- the same `vim.lsp.config(name, def)` + `vim.lsp.enable(name)`
            -- pattern mason-lspconfig uses internally.
            --
            -- IMPORTANT: no other spec may declare a `config` function for
            -- `neovim/nvim-lspconfig`. Lazy merges same-plugin specs by
            -- name; the last `config` function wins. A duplicate in nix.lua
            -- previously overwrote this entire config body.

            -- clangd: from clang-tools in the nix closure. Provides
            -- clang-format (conform) and clang-tidy alongside the LSP.
            vim.lsp.config("clangd", {
                capabilities = capabilities,
                cmd = { "clangd" },
                filetypes = { "c", "c.doxygen", "cpp", "cpp.doxygen", "objc", "objcpp", "cuda" },
                root_markers = {
                    ".clangd", ".clang-tidy", ".clang-format",
                    "compile_commands.json", "compile_flags.txt",
                    "configure.ac", ".git",
                },
                on_init = function(client, init_result)
                    if init_result.offsetEncoding then
                        client.offset_encoding = init_result.offsetEncoding
                    end
                end,
            })

            -- nixd: from devPkgs in the nix closure. lspconfig doesn't ship
            -- a nixd def; hand-write. Includes nixpkgs.expr for package
            -- resolution and options.nixos.expr for NixOS module introspection.
            vim.lsp.config("nixd", {
                capabilities = capabilities,
                cmd = { "nixd" },
                filetypes = { "nix" },
                root_markers = { ".git", "flake.nix" },
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
                        formatting = { command = { "nixfmt" } },
                    },
                },
            })

            -- Hand-tuned defs for servers that need settings beyond what
            -- mason-lspconfig ships by default.
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

            -- marksman (markdown LSP) is .NET; needs ICU or invariant mode.
            vim.env.DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1"

            vim.lsp.enable({ "lua_ls", "zls", "clangd", "nixd", "html", "cssls", "marksman", "sqls", "bashls", "wgsl_analyzer", "vtsls", "pyright" })
            vim.g.zig_fmt_parse_errors = 0
            vim.g.zig_fmt_autosave = 0

            local cmp_select = { behavior = cmp.SelectBehavior.Select }

            -- EXPERIMENT: completion diversity tuning.
            -- Each knob is isolated so you can flip one without touching the
            -- rest. Defaults match upstream nvim-cmp.
            --   * per-source max_item_count caps how many items a source may
            --     contribute (applied pre-sort: poorly-matched items may win).
            --     nil = unlimited.
            --   * per-source priority adds a flat score bonus (view.lua:
            --     e.score = e.score + (config.priority or index-based bonus)).
            --   * comparators run in order; first non-nil answer decides the
            --     pair. compare.scopes (treesitter) ranks locals above globals.
            local cmp_sources = cmp.config.sources({
                { name = 'nvim_lsp', max_item_count = 10, priority = 1 },
                { name = 'luasnip',  max_item_count = 5,  priority = 2 },
                { name = 'cmp_ai',   max_item_count = 3,  priority = 3 },
            }, {
                { name = 'buffer',   max_item_count = 6 },
            })

            local cmp_sorting = {
                priority_weight = 2,
                comparators = {
                    cmp.config.compare.offset,
                    cmp.config.compare.exact,
                    cmp.config.compare.score,
                    cmp.config.compare.recently_used,
                    cmp.config.compare.locality,
                    cmp.config.compare.scopes,
                    cmp.config.compare.kind,
                    cmp.config.compare.sort_text,
                    cmp.config.compare.length,
                    cmp.config.compare.order,
                },
            }

            cmp.setup({
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body)
                    end,
                },
                formatting = {
                    format = function(entry, vim_item)
                        local source_names = {
                            nvim_lsp = "[LSP]",
                            luasnip = "[Snip]",
                            cmp_ai = "[AI]",
                            buffer = "[Buf]",
                        }
                        vim_item.menu = source_names[entry.source.name] or ""
                        return vim_item
                    end,
                },
                sorting = cmp_sorting,
                mapping = cmp.mapping.preset.insert({
                    ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                    ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
                    ["<C-Space>"] = cmp.mapping.complete(),
                }),
                sources = cmp_sources,
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

            -- Buffer-local LSP keymaps, set on attach for any server.
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("lsp_attach", {}),
                callback = function(args)
                    local bufnr = args.buf
                    local nmap = function(keys, fn, desc)
                        vim.keymap.set("n", keys, fn, { buffer = bufnr, desc = desc })
                    end
                    nmap("gd", vim.lsp.buf.definition, "Go to definition")
                    nmap("grr", vim.lsp.buf.references, "Find references")
                    nmap("gri", vim.lsp.buf.implementation, "Find implementations")
                    nmap("grn", vim.lsp.buf.rename, "Rename symbol")
                    nmap("K", vim.lsp.buf.hover, "Hover")
                    nmap("<leader>la", vim.lsp.buf.code_action, "Code action")
                end,
            })

            -- Focusable diagnostic float under the cursor (scrollable window).
            vim.keymap.set("n", "gl", function()
                vim.diagnostic.open_float(0, {
                    scope = "cursor",
                    focusable = true,
                    border = "rounded",
                })
            end, { desc = "Diagnostic float" })

            -- LspRestart lives in remap.lua as <leader>zig.
        end
    },
}
