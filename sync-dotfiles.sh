#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./sync-dotfiles pull   # repo -> live system
#   ./sync-dotfiles push   # live system -> repo
#   ./sync-dotfiles diff   # inspect differences
#
# Run `pull` manually first after cloning/restoring this repo.

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

cmd="${1:-diff}"

copy_file() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  if [[ ! -e "$src" ]]; then
    echo "skip missing: $src"
    return
  fi

  rsync -av --mkpath "$src" "$dst"
}

diff_file() {
  local live="$1"
  local repo="$2"

  echo
  echo "== $live <-> $repo =="

  if [[ ! -e "$live" && ! -e "$repo" ]]; then
    echo "missing both"
    return
  fi

  if [[ ! -e "$live" ]]; then
    echo "missing live: $live"
    return
  fi

  if [[ ! -e "$repo" ]]; then
    echo "missing repo: $repo"
    return
  fi

  diff -u "$repo" "$live" || true
}

case "$cmd" in
  pull)
    for pair in "${FILES[@]}"; do
      live="${pair%%:*}"
      repo="${pair##*:}"
      copy_file "$repo" "$live"
    done
    echo "Pulled repo dotfiles into live locations."
    ;;

  push)
    for pair in "${FILES[@]}"; do
      live="${pair%%:*}"
      repo="${pair##*:}"
      copy_file "$live" "$repo"
    done
    echo "Pushed live dotfiles into repo."
    ;;

  diff)
    for pair in "${FILES[@]}"; do
      live="${pair%%:*}"
      repo="${pair##*:}"
      diff_file "$live" "$repo"
    done
    ;;

  *)
    echo "usage: $0 {pull|push|diff}" >&2
    exit 1
    ;;
esac
