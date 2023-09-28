# Path
# PATH=/run/current-system/sw/bin:$PATH

# Env vars
export EDITOR=nvim
export SUDO_EDITOR=nvim
# export NODE_SKIP_PLATFORM_CHECK=1
export ANDROID_HOME=~/Android/Sdk

# Deno apps
export PATH=$HOME/.deno/bin:$PATH

# Cargo apps
export PATH=$HOME/.cargo/bin:$PATH

# Man page settings
export BROWSER=google-chrome-stable
alias man-web='man --html'

# Nix
alias nix-stray-roots='nix-store --gc --print-roots | egrep -v "^(/nix/var|/run/\w+-system|\{memory)"'

# SSH setup
alias set-key='eval `ssh-agent -s` && ssh-add ~/.ssh/id_rsa'

# List path
alias list-path='tr ":" "\n" <<< "$PATH"'

# PostgreSQL database config
export PGUSER=postgres
export PGDATABASE=codinghermit

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

# Playlist downloader
yt_vdp () {
	yt-dlp -f $3 -o "%(playlist)s/%(playlist_index)s - %(title)s-%(id)s.%(ext)s" $1 -I "$2"
}

# DroidCam
detect_alsa_device () {
        pacmd load-module module-alsa-source device=hw:Loopback,1,0
}

# SSH setup
unlock_ssh () {
	# eval `ssh-agent`
	ssh-add ~/.ssh/id_rsa
}

# fzf setup
export FZF_DEFAULT_COMMAND='fd --type f'

# Nix shell setup
if [ -n "$IN_NIX_SHELL" ]; then
    PS1="(nix-shell)$PS1"
fi

# Retry on fail command
retry_command() {
    cmd="$@"
    while true; do
        $cmd
        exit_code=$?
        if [ $exit_code -eq 0 ]; then
            break  # Command succeeded, exit the loop
        else
            echo "Command '$cmd' failed with exit code $exit_code. Retrying in 1 minute..."
            sleep 10  # Wait for 10 seconds before retrying
        fi
    done
}

retry_sudo() {
    cmd="$@"

    # Start a background process to continuously refresh sudo access
    refresh_sudo() {
        while true; do
            sudo -v
            sleep 25
        done
    }

    # Run the command in the foreground
    (
        # Start the background process to refresh sudo access
        refresh_sudo &

        while true; do
            sudo -n $cmd < /dev/null
            exit_code=$?

            # Kill the background process if the command succeeded
            if [ $exit_code -eq 0 ]; then
                pkill -P $$
                break  # Command succeeded, exit the loop
            else
                echo "Command '$cmd' failed with exit code $exit_code. Retrying in 1 minute..."
                sleep 10  # Wait for 10 seconds before retrying
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

set -h # Fixes "bash: hash: hashing disabled" warning triggered by below code

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" > /dev/null  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm
export PNPM_HOME="/home/ryan/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
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
[ -f ~/.config/tabtab/bash/__tabtab.bash ] && . ~/.config/tabtab/bash/__tabtab.bash || true
