#!/usr/bin/env zsh
set -euo pipefail

# Usage:
#   ./sync-dotfiles.zsh status   # coarse divergence summary
#   ./sync-dotfiles.zsh diff     # full unified diff
#   ./sync-dotfiles.zsh bundle   # regenerate vendored shared chunks
#   ./sync-dotfiles.zsh pull     # live system/project -> repo
#   ./sync-dotfiles.zsh push     # repo -> live system/project; sudo only for /etc copies

PROTO="/run/media/ryan/nixos/Content/portfolio/prototype"

# ---- file lists ------------------------------------------------------------

# User dotfiles: repo <-> $HOME
# Explicit single-file entries
USER_FILES=(
  "$HOME/.bashrc:./.bashrc"
  "$HOME/.bash_profile:./.bash_profile"
  "$HOME/.zshrc:./.zshrc"

  # Emacs entrypoint
  "$HOME/.emacs.d/init.el:./emacs/init.el"

  # Emacs sidecar modules (explicit list – you can also glob these if you prefer)
  "$HOME/.emacs.d/lisp/core.el:./emacs/lisp/core.el"
  "$HOME/.emacs.d/lisp/completion.el:./emacs/lisp/completion.el"
  "$HOME/.emacs.d/lisp/place.el:./emacs/lisp/place.el"
  "$HOME/.emacs.d/lisp/discovery.el:./emacs/lisp/discovery.el"
  "$HOME/.emacs.d/lisp/terminal.el:./emacs/lisp/terminal.el"
  "$HOME/.emacs.d/lisp/ai.el:./emacs/lisp/ai.el"
  "$HOME/.emacs.d/lisp/cockpit.el:./emacs/lisp/cockpit.el"

  "$HOME/.config/hypr/hyprland.conf:./hypr/hyprland.conf"
  "$HOME/.config/waybar/config:./waybar/config"
  "$HOME/.config/waybar/style.css:./waybar/style.css"

  "$HOME/.config/starship.toml:./.config/starship.toml"

  "$HOME/.config/tmux/tmux.conf:./.config/tmux/tmux.conf"

  "$HOME/.wezterm.lua:./.wezterm.lua"

  # LLM/ASR scripts (hard-linked to ~/models/)
  "$HOME/models/run-llm.zsh:./scripts/run-llm.zsh"
  "$HOME/models/asr-hold.zsh:./scripts/asr-hold.zsh"

  # Neovim will be added automatically below (no need to list init.lua explicitly)
)

# Dynamically add everything under ~/.config/nvim
# (N) makes the glob null if the directory doesn't exist, avoiding errors
for livefile in $HOME/.config/nvim/**/*(.N); do
  rel="${livefile#$HOME/.config/nvim/}"
  USER_FILES+=("$livefile:./.config/nvim/$rel")
done

for repofile in ./.config/nvim/**/*(.N); do
  rel="${repofile#./.config/nvim/}"
  live="$HOME/.config/nvim/$rel"
  if [[ ! -e "$live" ]]; then
    USER_FILES+=("$live:./.config/nvim/$rel")
  fi
done

# Dynamically add everything under ~/.config/easyeffects
# (presets, autoload, db state — EasyEffects 8.x stores per-effect state in db/*.rc)
for livefile in $HOME/.config/easyeffects/**/*(.N); do
  rel="${livefile#$HOME/.config/easyeffects/}"
  USER_FILES+=("$livefile:./.config/easyeffects/$rel")
done

for repofile in ./.config/easyeffects/**/*(.N); do
  rel="${repofile#./.config/easyeffects/}"
  live="$HOME/.config/easyeffects/$rel"
  if [[ ! -e "$live" ]]; then
    USER_FILES+=("$live:./.config/easyeffects/$rel")
  fi
done

# System files: repo <-> /etc/nixos
SYSTEM_FILES=(
  "/etc/nixos/configuration.nix:./nixos/configuration.nix"
  "/etc/nixos/hardware-configuration.nix:./nixos/hardware-configuration.nix"
  "/etc/nixos/flake.nix:./nixos/flake.nix"
  "/etc/nixos/flake.lock:./nixos/flake.lock"
  # "/etc/nixos/asound.state:./nixos/asound.state"  # excluded — ALSA state too volatile for sync
)

# Prototype/devflake files: repo <-> prototype folder
PROTO_FILES=(
  "$PROTO/flake.nix:./devflake/flake.nix"
  "$PROTO/flake.lock:./devflake/flake.lock"
  "$PROTO/.envrc:./devflake/.envrc"
)

# ---- command dispatch ------------------------------------------------------

cmd="${1:-status}"

# ---- helpers ---------------------------------------------------------------

copy_file() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    echo "skip missing: $src"
    return
  fi

  mkdir -p "$(dirname "$dst")"
  rsync -av "$src" "$dst"
}

copy_file_sudo() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    echo "skip missing: $src"
    return
  fi

  sudo mkdir -p "$(dirname "$dst")"
  sudo rsync -av "$src" "$dst"
}

diff_file() {
  local live="$1"
  local repo="$2"

  echo
  echo "== $live <-> $repo =="

  [[ ! -e "$live" && ! -e "$repo" ]] && { echo "missing both"; return; }
  [[ ! -e "$live" ]] && { echo "missing live: $live"; return; }
  [[ ! -e "$repo" ]] && { echo "missing repo: $repo"; return; }

  diff -u "$repo" "$live" || true
}

status_file() {
  local live="$1"
  local repo="$2"
  local live_lines repo_lines live_time repo_time newer

  [[ ! -e "$live" && ! -e "$repo" ]] && return
  [[ ! -e "$live" ]] && { echo "MISSING LIVE  $live <- $repo"; return; }
  [[ ! -e "$repo" ]] && { echo "MISSING REPO  $repo <- $live"; return; }
  cmp -s "$live" "$repo" && return

  live_lines="$(wc -l < "$live")"
  repo_lines="$(wc -l < "$repo")"
  live_time="$(stat -c '%y' "$live" | cut -d. -f1)"
  repo_time="$(stat -c '%y' "$repo" | cut -d. -f1)"

  if [[ "$live" -nt "$repo" ]]; then
    newer="live newer"
  elif [[ "$repo" -nt "$live" ]]; then
    newer="repo newer"
  else
    newer="same mtime"
  fi

  echo "DIFF  $live <-> $repo | lines live:$live_lines repo:$repo_lines | $newer | live:$live_time repo:$repo_time"
}

bundle_shared() {
  copy_file "./shared/dev-pkgs.nix" "./nixos/shared/dev-pkgs.nix"
  copy_file "./shared/dev-pkgs.nix" "./devflake/shared/dev-pkgs.nix"
}

status_generated() {
  local src="./shared/dev-pkgs.nix"
  local nixos_copy="./nixos/shared/dev-pkgs.nix"
  local devflake_copy="./devflake/shared/dev-pkgs.nix"

  [[ ! -e "$src" ]] && { echo "MISSING SOURCE ./shared/dev-pkgs.nix"; return; }

  if [[ ! -e "$nixos_copy" ]]; then
    echo "STALE GENERATED  $nixos_copy missing"
  elif ! cmp -s "$src" "$nixos_copy"; then
    echo "STALE GENERATED  $nixos_copy differs from $src"
  fi

  if [[ ! -e "$devflake_copy" ]]; then
    echo "STALE GENERATED  $devflake_copy missing"
  elif ! cmp -s "$src" "$devflake_copy"; then
    echo "STALE GENERATED  $devflake_copy differs from $src"
  fi
}

check_proto() {
  if [[ ! -d "$PROTO" ]]; then
    echo "ERROR: prototype folder does not exist:"
    echo "  $PROTO"
    echo
    echo "Mount/create it first, or fix PROTO in this script."
    exit 1
  fi
}

all_pairs_status() {
  for pair in "${USER_FILES[@]}" "${SYSTEM_FILES[@]}" "${PROTO_FILES[@]}"; do
    status_file "${pair%%:*}" "${pair##*:}"
  done
}

all_pairs_diff() {
  for pair in "${USER_FILES[@]}" "${SYSTEM_FILES[@]}" "${PROTO_FILES[@]}"; do
    diff_file "${pair%%:*}" "${pair##*:}"
  done
}

# ---- main ------------------------------------------------------------------

case "$cmd" in
  status)
    all_pairs_status
    status_generated
    ;;

  diff)
    all_pairs_diff
    status_generated
    ;;

  bundle)
    bundle_shared
    echo "Bundled shared Nix chunks."
    ;;

  pull)
    check_proto

    for pair in "${USER_FILES[@]}"; do
      copy_file "${pair%%:*}" "${pair##*:}"
    done

    for pair in "${SYSTEM_FILES[@]}"; do
      copy_file "${pair%%:*}" "${pair##*:}"
    done

    for pair in "${PROTO_FILES[@]}"; do
      copy_file "${pair%%:*}" "${pair##*:}"
    done

    bundle_shared
    echo "Pulled live files into repo and refreshed generated chunks."
    ;;

  push)
    check_proto
    bundle_shared

    echo "Pushing user files..."
    for pair in "${USER_FILES[@]}"; do
      copy_file "${pair##*:}" "${pair%%:*}"
    done

    echo "Pushing system files..."
    for pair in "${SYSTEM_FILES[@]}"; do
      copy_file_sudo "${pair##*:}" "${pair%%:*}"
    done

    echo "Pushing prototype/devflake files..."
    for pair in "${PROTO_FILES[@]}"; do
      copy_file "${pair##*:}" "${pair%%:*}"
    done

    echo "Pushing generated shared chunks..."
    copy_file_sudo "./nixos/shared/dev-pkgs.nix" "/etc/nixos/shared/dev-pkgs.nix"
    copy_file "./devflake/shared/dev-pkgs.nix" "$PROTO/shared/dev-pkgs.nix"

    echo "Pushed repo dotfiles into live locations."
    ;;

  *)
    echo "usage: $0 {status|diff|bundle|pull|push}" >&2
    exit 1
    ;;
esac
