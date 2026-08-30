#!/usr/bin/env zsh
set -euo pipefail

# Usage:
#   ./sync-dotfiles.zsh status   # coarse divergence summary
#   ./sync-dotfiles.zsh diff     # full unified diff
#   ./sync-dotfiles.zsh bundle   # regenerate vendored shared chunks
#   ./sync-dotfiles.zsh pull     # live system/project -> repo
#   ./sync-dotfiles.zsh push     # repo -> live system/project; sudo only for /etc copies
#
# Global flags (must come BEFORE the subcommand):
#   --dry-run, -n   Print what would be copied without writing anything.
#                    Pass-through to rsync --dry-run; also skips sudo prompts.

PROTO="/run/media/ryan/nixos/Content/portfolio/prototype"

# Lab repo: one-way consumer of the shared dev-pkgs.nix spec.
# The lab's own flake.nix imports the spec via relative path, so we only
# need to keep the spec file in sync — flake.nix / flake.lock / .envrc
# are lab-authored and stay where they are.
LAB="/home/ryan/Code/Repos/lab"

# ---- flag parsing ----------------------------------------------------------

DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    --) shift; break ;;
    -*)
      echo "unknown flag: $1" >&2
      exit 2
      ;;
    *) break ;;
  esac
done

cmd="${1:-status}"

# Sanity: refuse to push/pull if the dotfiles repo has uncommitted changes.
# Prevents overwriting live state with an in-progress edit that hasn't been
# reviewed. Skip check on status/diff/bundle (read-only) and on --dry-run
# (no writes either way).
check_repo_clean() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "ERROR: not inside a git repo" >&2
    exit 3
  fi
  local dirty
  dirty="$(git status --porcelain 2>/dev/null)"
  if [[ -n "$dirty" ]]; then
    echo "ERROR: dotfiles repo has uncommitted changes:" >&2
    echo "$dirty" | sed 's/^/  /' >&2
    echo "Commit or stash before $cmd." >&2
    exit 4
  fi
}

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

   "$HOME/.config/maki/init.lua:./.config/maki/init.lua"

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

# Lab files: dotfiles -> lab folder (one-way push of the spec).
# The lab's flake.nix imports from ./shared/dev-pkgs.nix in the lab repo,
# not from the submodule — nix flakes require build-time files to be
# tracked by the parent repo, and submodule contents aren't. So the spec
# is copied to a parent-tracked path and this entry keeps them in lockstep.
# The lab's flake.nix / flake.lock / .envrc are lab-authored wrappers
# and are not touched by this script.
LAB_FILES=(
  "./shared/dev-pkgs.nix:$LAB/shared/dev-pkgs.nix"
)

# Generated vendored copies: source-of-truth -> vendored.
# Tracked by `bundle_shared`; checked by `status_generated`.
GENERATED_PATHS=(
  "./shared/dev-pkgs.nix:./nixos/shared/dev-pkgs.nix"
  "./shared/dev-pkgs.nix:./devflake/shared/dev-pkgs.nix"
)

# Generated copies that get pushed to live locations (sudo for nixos).
# Only invoked on `push`, after `bundle_shared` has refreshed the vendored copies.
GENERATED_PUSH=(
  "./nixos/shared/dev-pkgs.nix:/etc/nixos/shared/dev-pkgs.nix"
  "./devflake/shared/dev-pkgs.nix:$PROTO/shared/dev-pkgs.nix"
)

# ---- command dispatch ------------------------------------------------------

# ---- helpers ---------------------------------------------------------------

# Common rsync flags. --dry-run is added when DRY_RUN=1.
rsync_flags() {
  echo -av${DRY_RUN:+n}
}

copy_file() {
  local src="$1"
  local dst="$2"
  local flags
  flags="$(rsync_flags)"

  if [[ ! -e "$src" ]]; then
    echo "skip missing: $src"
    return
  fi

  mkdir -p "$(dirname "$dst")"
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "  [dry-run] rsync $flags $src $dst"
    rsync $flags "$src" "$dst" 2>&1 | sed 's/^/  [dry-run] /' || true
  else
    rsync $flags "$src" "$dst"
  fi
}

copy_file_sudo() {
  local src="$1"
  local dst="$2"
  local flags
  flags="$(rsync_flags)"

  if [[ ! -e "$src" ]]; then
    echo "skip missing: $src"
    return
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    echo "  [dry-run] sudo rsync $flags $src $dst"
    return
  fi

  sudo mkdir -p "$(dirname "$dst")"
  sudo rsync $flags "$src" "$dst"
}

# Timestamp-aware sync: only copy if source strictly newer than destination.
# Usage: sync_file_directional <src> <dst> <copy_fn> <label>
# copy_fn: "copy_file" or "copy_file_sudo"
sync_file_directional() {
  local src="$1"
  local dst="$2"
  local copy_fn="$3"
  local label="$4"

  [[ ! -e "$src" && ! -e "$dst" ]] && return
  [[ ! -e "$src" ]] && { echo "  MISSING SRC: $src ($label)"; return; }
  [[ ! -e "$dst" ]] && { $copy_fn "$src" "$dst"; echo "  SYNC (dst missing): $src -> $dst"; return; }
  cmp -s "$src" "$dst" && return

  if [[ "$src" -nt "$dst" ]]; then
    $copy_fn "$src" "$dst"
    echo "  SYNC: $src -> $dst"
  else
    echo "  CONFLICT: $dst newer or same mtime, content differs"
    echo "    src: $(stat -c '%y' "$src" | cut -d. -f1)  dst: $(stat -c '%y' "$dst" | cut -d. -f1)"
    echo "    $label — resolve manually, then touch authoritative side."
  fi
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

# LAB_FILES is one-way: dotfiles repo -> lab repo. The destination is NOT a
# live config, it's a vendored copy, so label it that way to avoid the
# "live newer" confusion we hit before.
status_lab() {
  local src="./shared/dev-pkgs.nix"
  local dst="$LAB/shared/dev-pkgs.nix"

  [[ ! -e "$src" && ! -e "$dst" ]] && return
  [[ ! -e "$src" ]] && { echo "MISSING SOURCE  $src"; return; }
  [[ ! -e "$dst" ]] && { echo "STALE LAB COPY  $dst missing (source: $src)"; return; }
  cmp -s "$src" "$dst" && return

  echo "STALE LAB COPY  $dst  (source-of-truth: $src, $(stat -c '%y' "$src" | cut -d. -f1))"
}

diff_lab() {
  local src="./shared/dev-pkgs.nix"
  local dst="$LAB/shared/dev-pkgs.nix"

  echo
  echo "== $src (source of truth) -> $dst (lab vendored copy) =="

  [[ ! -e "$src" && ! -e "$dst" ]] && { echo "missing both"; return; }
  [[ ! -e "$dst" ]] && { echo "missing lab copy: $dst"; return; }
  [[ ! -e "$src" ]] && { echo "missing source: $src"; return; }

  diff -u "$dst" "$src" || true
}

bundle_shared() {
  for pair in "${GENERATED_PATHS[@]}"; do
    copy_file "${pair%%:*}" "${pair##*:}"
  done
}

status_generated() {
  for pair in "${GENERATED_PATHS[@]}"; do
    local src="${pair%%:*}"
    local dst="${pair##*:}"
    if [[ ! -e "$src" ]]; then
      echo "MISSING SOURCE  $src"
      continue
    fi
    if [[ ! -e "$dst" ]]; then
      echo "STALE GENERATED  $dst missing"
    elif ! cmp -s "$src" "$dst"; then
      echo "STALE GENERATED  $dst differs from $src"
    fi
  done
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

if [[ "$DRY_RUN" == "1" ]]; then
  echo "[DRY-RUN MODE — no writes will occur]"
  echo
fi

case "$cmd" in
  status)
    all_pairs_status
    status_lab
    status_generated
    ;;
  diff)
    all_pairs_diff
    diff_lab
    status_generated
    ;;
  bundle)
    bundle_shared
    echo "Bundled shared Nix chunks."
    ;;
   pull)
     check_repo_clean
     check_proto

     for pair in "${USER_FILES[@]}"; do
       sync_file_directional "${pair%%:*}" "${pair##*:}" "copy_file" "user"
     done

     for pair in "${SYSTEM_FILES[@]}"; do
       sync_file_directional "${pair%%:*}" "${pair##*:}" "copy_file_sudo" "system"
     done

     for pair in "${PROTO_FILES[@]}"; do
       sync_file_directional "${pair%%:*}" "${pair##*:}" "copy_file" "proto"
     done

     bundle_shared
     echo "Pulled live files into repo and refreshed generated chunks."
     echo "Run 'push' (or run 'sync-dotfiles.zsh push' explicitly) to copy the lab vendored copy."
    ;;

   push)
     check_repo_clean
     check_proto

     bundle_shared

     echo "Pushing user files..."
     for pair in "${USER_FILES[@]}"; do
       sync_file_directional "${pair##*:}" "${pair%%:*}" "copy_file" "user"
     done

     echo "Pushing system files..."
     for pair in "${SYSTEM_FILES[@]}"; do
       sync_file_directional "${pair##*:}" "${pair%%:*}" "copy_file_sudo" "system"
     done

     echo "Pushing prototype/devflake files..."
     for pair in "${PROTO_FILES[@]}"; do
       sync_file_directional "${pair##*:}" "${pair%%:*}" "copy_file" "proto"
     done

     echo "Pushing lab files..."
     for pair in "${LAB_FILES[@]}"; do
       sync_file_directional "${pair##*:}" "${pair%%:*}" "copy_file" "lab"
     done

     echo "Pushing generated chunks to live locations..."
     for pair in "${GENERATED_PUSH[@]}"; do
       local src="${pair%%:*}"
       local dst="${pair##*:}"
       # First is sudo (nixos), second is regular (proto).
       if [[ "$dst" == /etc/* ]]; then
         sync_file_directional "$src" "$dst" "copy_file_sudo" "nixos generated"
       else
         sync_file_directional "$src" "$dst" "copy_file" "proto generated"
       fi
     done

     echo "Pushed repo dotfiles into live locations."
     ;;

  *)
    echo "usage: $0 [--dry-run|-n] {status|diff|bundle|pull|push}" >&2
    exit 1
    ;;
esac
