# Neovim Lazy Plugins

Plugins loaded via [lazy.nvim](https://github.com/folke/lazy.nvim) for the `ryan` config.

| File | Plugin | Purpose |
|------|--------|---------|
| `cloak.lua` | [cloak.nvim](https://github.com/laytan/cloak.nvim) | Masks secrets in `.env`, `wrangler.toml`, `.dev.vars` files by replacing values after `=` with `*`. Uses the `Comment` highlight group. |
| `cmp.lua` | [cmp-ai](https://github.com/RyanCargan/cmp-ai) | AI completion source for `nvim-cmp` backed by a local llama.cpp server. Supports RWKV (Unicode Flower FIM) and standard Transformer models. Toggle models at runtime with `require('cmp_ai.config'):set_model(...)`. |
| `colors.lua` | [brightburn.vim](https://github.com/erikbackman/brightburn.vim), [tokyonight.nvim](https://github.com/folke/tokyonight.nvim), [gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim), [rose-pine](https://github.com/rose-pine/neovim) | Loads and configures multiple color schemes. Provides `ColorMyPencils()` helper that sets the scheme with transparent backgrounds. Auto-selects `tokyonight-night` for Zig files, `rose-pine-moon` otherwise. |
| `conform.nvim` | [conform.nvim](https://github.com/stevearc/conform.nvim) | Auto-formats on save with a 5s timeout. Configures formatters per filetype: `clang-format` (C/C++), `stylua` (Lua), `gofmt` (Go), `odinfmt` (Odin), `prettier` (JS/TS/JSON), `mix` (Elixir). Falls back to LSP formatting. Maps `<leader>f` to manually format the current buffer. |
| `dap.lua` | [nvim-dap](https://github.com/mfussenegger/nvim-dap), [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui), [mason-nvim-dap](https://github.com/jay-babu/mason-nvim-dap) | Debugging setup. Keybindings: F8 (continue), F10 (step over), F11 (step into), F12 (step out), `<leader>b` (toggle breakpoint), `<leader>B` (conditional breakpoint). DAP UI panels for REPL, stacks, scopes, console, watches, and breakpoints toggled via `<leader>dr`, `<leader>ds`, `<leader>dw`, `<leader>dc`, `<leader>dS`, `<leader>db`. Auto-installs [delve](https://github.com/go-delve/delve) for Go debugging via mason. |
| `fugitive.lua` | [vim-fugitive](https://github.com/tpope/vim-fugitive) | Git integration. `<leader>gs` opens `:Git`, `<leader>p` pushes, `<leader>P` pulls with rebase, `<leader>t` pushes with upstream tracking. In fugitive buffers: `gu` diffs against `//2`, `gh` diffs against `//3`. |
| `golf.lua` | [golf](https://github.com/vuciv/golf) | A minimal plugin — placeholder entry for the `vuciv/golf` utility. |
| `wezterm.lua` | [wezterm.nvim](https://github.com/willothy/wezterm.nvim) | Wezterm terminal emulator integration. Enables `config = true` for basic setup; used with `<leader>wt` to switch tabs (see `remap.lua`). |

---

### Removed

- **`sessionizer.lua`** — A workspace session manager (now deleted). Used [z.lua](https://github.com/skywind3000/z.lua) for directory history and [wezterm](https://wezfurlong.org/wezterm/) to create/switch workspaces. Provided `pick_and_switch()` to select a directory and open it in a named wezterm workspace, and `switch_workspace()` to cycle existing workspaces.