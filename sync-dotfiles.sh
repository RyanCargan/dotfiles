#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./sync-dotfiles.sh status   # coarse divergence summary
#   ./sync-dotfiles.sh diff     # full unified diff
#   ./sync-dotfiles.sh bundle   # regenerate vendored shared chunks
#   ./sync-dotfiles.sh pull     # live system/project -> repo
#   ./sync-dotfiles.sh push     # repo -> live system/project; sudo only for /etc copies

PROTO="/run/media/ryan/nixos/Content/portfolio/prototype"

# User dotfiles: repo <-> $HOME
USER_FILES=(
  "$HOME/.bashrc:./.bashrc"
  "$HOME/.bash_profile:./.bash_profile"

  "$HOME/.config/hypr/hyprland.conf:./hypr/hyprland.conf"
  "$HOME/.config/waybar/config:./waybar/config"
  "$HOME/.config/waybar/style.css:./waybar/style.css"
)

# System files: repo <-> /etc/nixos
# Push uses sudo per-copy, not sudo for the whole script.
SYSTEM_FILES=(
  "/etc/nixos/configuration.nix:./nixos/configuration.nix"
  "/etc/nixos/hardware-configuration.nix:./nixos/hardware-configuration.nix"
  "/etc/nixos/flake.nix:./nixos/flake.nix"
  "/etc/nixos/flake.lock:./nixos/flake.lock"
)

# Prototype/devflake files: repo <-> prototype folder.
# Generated/vendor shared chunks are intentionally NOT listed here.
PROTO_FILES=(
  "$PROTO/flake.nix:./devflake/flake.nix"
  "$PROTO/flake.lock:./devflake/flake.lock"
  "$PROTO/.envrc:./devflake/.envrc"
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
  # Source of truth:
  #   ./shared/dev-pkgs.nix
  #
  # Vendored/generated copies:
  #   ./nixos/shared/dev-pkgs.nix
  #   ./devflake/shared/dev-pkgs.nix
  #
  # Edit only the source of truth, then run bundle/push.
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
    # Pull live user/system/prototype state into repo.
    #
    # Note: generated shared chunks are not pulled from live locations.
    # Edit ./shared/dev-pkgs.nix, then run bundle.
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
    # Push repo state to user/system/prototype.
    #
    # Important:
    #   Do NOT run this script with sudo.
    #   It uses sudo only for /etc/nixos copies.
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
