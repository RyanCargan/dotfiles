#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./sync-dotfiles.sh status   # coarse divergence summary only
#   ./sync-dotfiles.sh diff     # full unified diff
#   ./sync-dotfiles.sh pull     # live system -> repo
#   sudo ./sync-dotfiles.sh push # repo -> live system

FILES=(
  "$HOME/.bashrc:./.bashrc"
  "$HOME/.bash_profile:./.bash_profile"

  "$HOME/.config/hypr/hyprland.conf:./hypr/hyprland.conf"
  "$HOME/.config/waybar/config:./waybar/config"
  "$HOME/.config/waybar/style.css:./waybar/style.css"

  "/etc/nixos/configuration.nix:./nixos/configuration.nix"
  "/etc/nixos/hardware-configuration.nix:./nixos/hardware-configuration.nix"
  "/etc/nixos/flake.nix:./nixos/flake.nix"
  "/etc/nixos/flake.lock:./nixos/flake.lock"
)

cmd="${1:-status}"

copy_file() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    echo "skip missing: $src"
    return
  fi

  mkdir -p "$(dirname "$dst")"
  rsync -av --mkpath "$src" "$dst"
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

case "$cmd" in
  status)
    # Coarse summary only; skips identical files.
    for pair in "${FILES[@]}"; do
      status_file "${pair%%:*}" "${pair##*:}"
    done
    ;;

  diff)
    # Full unified diff.
    for pair in "${FILES[@]}"; do
      diff_file "${pair%%:*}" "${pair##*:}"
    done
    ;;

  pull)
    # Pull current live machine state into this repo.
    for pair in "${FILES[@]}"; do
      copy_file "${pair%%:*}" "${pair##*:}"
    done
    echo "Pulled live dotfiles into repo."
    ;;

  push)
    # Push repo files into live machine locations.
    for pair in "${FILES[@]}"; do
      copy_file "${pair##*:}" "${pair%%:*}"
    done
    echo "Pushed repo dotfiles into live locations."
    ;;

  *)
    echo "usage: $0 {status|diff|pull|push}" >&2
    exit 1
    ;;
esac
