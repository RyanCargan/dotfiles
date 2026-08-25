# shellcheck disable=SC2148
# Path
# PATH=/run/current-system/sw/bin:$PATH

# Local secrets; never committed.
if [ -f "$HOME/.config/secrets/env" ]; then
  set -a
  . "$HOME/.config/secrets/env"
  set +a
fi

# ----- SSH agent: start if not running -----
mkdir -p "$HOME/.ssh"

# Load saved environment if it exists
[ -f "$HOME/.ssh/agent-env" ] && source "$HOME/.ssh/agent-env"

# Check if agent is alive
if ! ssh-add -l &>/dev/null; then
    echo "Starting ssh-agent..." >&2
    eval "$(ssh-agent -s)" > /dev/null
    # Save environment for future shells
    ssh-agent -s > "$HOME/.ssh/agent-env"
    source "$HOME/.ssh/agent-env"
    # Optional: auto-add your default key
    # ssh-add ~/.ssh/id_rsa 2>/dev/null
fi

# Env vars
export EDITOR=nvim
export SUDO_EDITOR=nvim
# Enable zsh vi-mode keybindings (hjkl cursor motion, 0/$ line edges, Esc to toggle modes)
bindkey -v
# export NODE_SKIP_PLATFORM_CHECK=1
export ANDROID_HOME=~/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Node apps
export PATH=$HOME/.npm-packages/bin:$PATH

# Deno apps
export PATH=$HOME/.deno/bin:$PATH

# Cargo apps
export PATH=$HOME/.cargo/bin:$PATH

# Misc tools
export PATH=$HOME/Tools:$PATH
export PATH=$HOME/Tools/cabbage/bin:$PATH

# Man page settings
export BROWSER=firefox-nightly
alias man-web='man --html'

# Nix
alias nix-stray-roots='nix-store --gc --print-roots | egrep -v "^(/nix/var|/run/\w+-system|\{memory)"'

# SSH setup
alias set-key='eval `ssh-agent -s` && ssh-add ~/.ssh/id_rsa'

# List path
alias list-path='tr ":" "\n" <<< "$PATH"'

# PostgreSQL database config
export PGUSER=admin
export PGDATABASE=central

# UV
export UV_LINK_MODE="clone"
export UV_CACHE_DIR="/run/media/ryan/nixos/.cache/uv/"
export UV_PYTHON_PREFERENCE="only-managed"
export UV_CONCURRENT_DOWNLOADS="3"
export UV_NATIVE_TLS="1"

# Java config
# export JAVA_HOME=$(readlink -e $(type -p javac) | sed  -e 's/\/bin\/javac//g')

# Golang config
# export PATH=$PATH:$HOME/app/go/bin

# SSH config
alias setup-ssh='eval `ssh-agent -s` && ssh-add ~/.ssh/id_rsa'

# Refresh desktop after installs
alias refresh-desktop='xfce4-panel -r && xfwm4 --replace &'

# Video downloader
yt_vdq () {
    local playlist=''
	local items=''
    if [[ -n $4 ]]; then
        playlist='%(playlist_autonumber)s-'
		items="--playlist-items $4"
    else
        playlist=''
		items=''
    fi
    local pString="yt-dlp --add-metadata --embed-metadata --embed-chapters --all-subs --embed-subs --embed-thumbnail -o ${playlist}%(title)s-%(id)s.%(ext)s -f"
	if [[ -n $4 ]]; then
	 ${pString} $3$2 $1 ${items}
	elif [[ -n $3 ]]; then
        ${pString} $3$2 $1
    else
        ${pString} $2 $1
    fi
}

# Playlist downloader with subtitle embedding and separate subtitle file download
yt_vdp () {
    local subtitle_lang="en.*,ja"
    yt-dlp  --embed-subs --sub-langs ${subtitle_lang} --write-subs -f $3 -o "%(playlist)s/%(playlist_index)s - %(title)s-%(id)s.%(ext)s" $1 -I "$2"
}

# DroidCam
detect_alsa_device () {
        pacmd load-module module-alsa-source device=hw:Loopback,1,0
}

# SSH setup
unlock_ssh () {
	ssh-add ~/.ssh/id_rsa
}

unlock_ssh2 () {
	ssh-add ~/.ssh/id_rsa2
}

unlock_ssh3 () {
	ssh-add ~/.ssh/id_rsa3
}

unlock_ssh4 () {
	ssh-add ~/.ssh/id_rsa4
}

lock_ssh () {
	ssh-add -d ~/.ssh/id_rsa
}

lock_ssh2 () {
	ssh-add -d ~/.ssh/id_rsa2
}

lock_ssh3 () {
	ssh-add -d ~/.ssh/id_rsa3
}

lock_ssh4 () {
	ssh-add -d ~/.ssh/id_rsa4
}

unlock_ed25519 () {
	ssh-add ~/.ssh/id_ed25519
}

lock_ed25519 () {
	ssh-add -d ~/.ssh/id_ed25519
}

#--- Network mgmt helper funcs---#

capture_traffic() {
  if [ -z "$1" ]; then
    echo "Usage: capture_traffic <PID>"
    return 1
  fi

  PID=$1
  OUTPUT_FILE="capture_${PID}.pcap"

  echo "Starting tcpdump for PID $PID..."
  sudo tcpdump -i any -w "$OUTPUT_FILE" "pid $PID"

  echo "Traffic capture started. Output saved to $OUTPUT_FILE."
}

# fzf setup
export FZF_DEFAULT_COMMAND='fd --type f'

# Nix shell setup
if [ -n "$IN_NIX_SHELL" ]; then
    PS1="(nix-shell)$PS1"
fi

# Retry on fail command
retry_command() {
    local cmd=("$@")
    while true; do
        "${cmd[@]}"
        exit_code=$?
        if [ $exit_code -eq 0 ]; then
            break
        else
            echo "Command '${cmd[*]}' failed with exit code $exit_code. Retrying in 1 minute..."
            sleep 10
        fi
    done
}

retry_sudo() {
    local cmd=("$@")

    refresh_sudo() {
        while true; do
            sudo -v
            sleep 25
        done
    }

    (
        refresh_sudo &

        while true; do
            sudo -n "${cmd[@]}" < /dev/null
            exit_code=$?

            if [ $exit_code -eq 0 ]; then
                pkill -P $$
                break
            else
                echo "Command '${cmd[*]}' failed with exit code $exit_code. Retrying in 1 minute..."
                sleep 10
            fi
        done
    )
}

# Backups
backup_cyberpunk () {
	rsync -avP "/run/media/ryan/ubuntu/SteamLibrary/steamapps/compatdata/1091500/pfx/drive_c/users/steamuser/Saved Games/CD Projekt Red/Cyberpunk 2077" /run/media/ryan/ubuntu/SaveBackups/
}

# Managers
. "$HOME/.asdf/asdf.sh"
. "$HOME/.asdf/completions/asdf.bash"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" > /dev/null
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# pnpm
# export PNPM_HOME="/home/ryan/.local/share/pnpm"
# case ":$PATH:" in
#   *":$PNPM_HOME:"*) ;;
#   *) export PATH="$PNPM_HOME:$PATH" ;;
# esac
# pnpm end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# __conda_setup="$('/home/ryan/.conda/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
#     eval "$__conda_setup"
# else
#     if [ -f "/home/ryan/.conda/etc/profile.d/conda.sh" ]; then
#         . "/home/ryan/.conda/etc/profile.d/conda.sh"
#     else
#         export PATH="/home/ryan/.conda/bin:$PATH"
#     fi
# fi
# unset __conda_setup
# <<< conda initialize <<<

# tabtab source for packages
# uninstall by removing these lines
# [ -f ~/.config/tabtab/zsh/__tabtab.zsh ] && . ~/.config/tabtab/zsh/__tabtab.zsh || true

eval "$(direnv hook zsh)"

# Terraform completion (zsh uses compinit; bash-style complete is not available)
# For zsh terraform completion, install zsh-terraform or use compinit:
# autoload -Uz compinit && compinit
# compdef _terraform terraform

eval "$(starship init zsh)"

# 1. OpenRouter Connection
# export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
# export ANTHROPIC_AUTH_TOKEN="${OPENROUTER_API_KEY:-}"
# export ANTHROPIC_API_KEY=""

# 2. Free Model Assignments
# export ANTHROPIC_DEFAULT_SONNET_MODEL="tencent/hy3-preview:free"
# export ANTHROPIC_DEFAULT_OPUS_MODEL="meta-llama/llama-3.3-70b-instruct:free"
# export ANTHROPIC_DEFAULT_HAIKU_MODEL="google/gemma-3-12b-it:free"
# export CLAUDE_CODE_SUBAGENT_MODEL="nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free"

export PATH="$HOME/.local/bin:$PATH"

# z.lua
eval "$(lua ~/zsh-plugins/z.lua/z.lua --init zsh enhanced once fzf)"

# opencode
export PATH=/home/ryan/.opencode/bin:$PATH

alias nvg="nvim -c 'tab Git'"
