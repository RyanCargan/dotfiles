# Dotfiles

Apply the repository state with:

```sh
./sync-dotfiles.sh push
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

## Shell: zsh

The default shell is now **zsh**. The repo tracks `.zshrc` (ported from
`.bashrc`) and the NixOS config sets `users.ryan.shell = pkgs.zsh` plus
`programs.zsh` with autosuggestions, syntax highlighting, and oh-my-zsh.

Key differences from the old `.bashrc`:
- `direnv hook zsh` instead of `direnv hook bash`
- `starship init zsh` instead of `starship init bash`
- `tabtab` zsh completion path instead of bash
- `conda init` block is commented out (same as before)
- `complete -C` for terraform works in zsh via the `compinit` integration

## tmux

Config lives at `.config/tmux/tmux.conf` and is synced to `~/.tmux.conf`
(via the sync script). TPM plugins are installed at `~/.tmux/plugins/`.

## nvim

Config lives at `.config/nvim/init.vim` and is synced to
`~/.config/nvim/init.vim`. Uses vim-plug for plugin management.

## Emacs, Evil, and Pi

The NixOS configuration installs Emacs with Evil and `pi-coding-agent.el`, plus
the Pi CLI. After rebuilding, authenticate once from a terminal:

```sh
pi
```

Inside Pi, run `/login`, choose **OpenAI Codex**, then complete the browser OAuth
flow using the OpenAI account with the ChatGPT Plus subscription. Pi stores and
refreshes the credentials in `~/.pi/agent/auth.json`; this file is not synced or
committed.

Start the Emacs frontend with `M-x pi`, `C-c a`, or `SPC a p` in Evil normal
state. Use `C-c C-c` in the input pane to send a prompt and `C-c C-p` to open
the Pi command menu.

Press `SPC` in Evil normal mode to open the contextual key guide. Common entry
points are:

| Key | Action |
| --- | --- |
| `F1` / `SPC ?` | Show bindings for the current mode |
| `SPC p p` | Open a project in a named tab |
| `SPC p f` | Find a file in the current project |
| `SPC p s` | Search the project with ripgrep |
| `SPC p a` | Start Pi at the current project root |
| `SPC f t` | Toggle Treemacs |
| `SPC g g` | Open Magit status |
| `SPC o d` | Open Dired for the current file |
| `SPC o a` | Open the Org agenda |
| `SPC o c` | Open Calc |

Use `C-x C-f` or `SPC o r` with a TRAMP path such as
`/ssh:user@host:/path/to/file` to open remote files. In Dired, use `C-x C-q` to
enter Wdired and edit filenames as text.
