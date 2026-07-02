# Dotfiles

Apply the repository state with:

```sh
./sync-dotfiles.sh push
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

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
