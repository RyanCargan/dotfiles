#!/usr/bin/env zsh
# ASR toggle-to-record for Hyprland bind (single key)
# Toggle: asr-hold.zsh toggle
# Legacy: asr-hold.zsh start / asr-hold.zsh stop
set -uo pipefail

AUDIO_DIR="${AUDIO_DIR:-$HOME/models/Audio}"
XD="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
ASR_WAV="$XD/asr-hold.wav"
ASR_PID_FILE="$XD/asr-rec.pid"
ASR_START_FILE="$XD/asr-started"
ASR_NOTIFY_APP="ASR-rec"
PORT_ASR="${PORT_ASR:-8082}"

is_recording() {
  [[ -f "$ASR_PID_FILE" ]] && kill -0 "$(cat "$ASR_PID_FILE" 2>/dev/null)" 2>/dev/null
}

start_recording() {
  mkdir -p "$AUDIO_DIR" 2>/dev/null

  # Use the physical mic source. "Easy Effects Source" is a virtual source that
  # produces silence (-91 dB) when recorded directly — no app is consuming it.
  # pw-record also produces 48kHz stereo which llama.cpp mtmd decodes poorly.
  # ffmpeg with -f pulse from the physical source captures 16kHz mono directly.
  target=$(wpctl status 2>/dev/null \
    | grep -oP '\d+(?=\.\s+Starship.*Analog Stereo)' | head -n1)
  target=${target:-62}
  wpctl set-default "$target" 2>/dev/null || true

  ffmpeg -hide_banner -loglevel error -y \
    -f pulse -i @DEFAULT_SOURCE@ \
    -ac 1 -ar 16000 -acodec pcm_s16le \
    "$ASR_WAV" >/dev/null 2>&1 &
  local pid=$!
  echo "$pid" > "$ASR_PID_FILE"
  date +%s > "$ASR_START_FILE"

  # Persistent notification (no timeout) — stays until stop
  notify-send -e -t 0 -u normal "$ASR_NOTIFY_APP" "● Recording — tap again to stop" 2>/dev/null || true
}

stop_recording() {
  local pid
  pid=$(cat "$ASR_PID_FILE" 2>/dev/null)
  if [[ -n "$pid" ]]; then
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null || true
  fi

  rm -f "$ASR_PID_FILE" "$ASR_START_FILE"

  # Dismiss recording notification
  notify-send -i audio-input-microphone "ASR-rec" "Recording stopped" 2>/dev/null || true

  if [[ ! -f "$ASR_WAV" ]]; then
    notify-send -t 1500 "ASR" "no audio" 2>/dev/null
    exit 1
  fi

  # Wait for ffmpeg flush
  sleep 0.5

  # Always persist WAV immediately to ring buffer (parallel, non-blocking).
  # Decoupled from ASR success so audio is saved even if endpoint hangs.
  local idx wav
  idx=$(cat "$XD/asr-idx" 2>/dev/null || echo 0)
  idx=$(( idx % 3 ))
  wav="$AUDIO_DIR/asr-${idx}.wav"
  cp "$ASR_WAV" "$wav" &
  local persist_pid=$!
  echo $(( (idx + 1) % 3 )) > "$XD/asr-idx"

  # Send WAV to ASR endpoint
  local text
  text=$(curl -sf --max-time 30 \
    -F file=@"$ASR_WAV" \
    -F model=qwen3-asr \
    -F response_format=json \
    "http://127.0.0.1:$PORT_ASR/v1/audio/transcriptions" 2>/dev/null \
    | jq -r '.text // empty' 2>/dev/null)

  # Strip Qwen3-ASR wrapper: "language English<asr_text>actual text"
  text=${text#*<asr_text>}

  wait "$persist_pid" 2>/dev/null || true

  if [[ -n "$text" ]]; then
    printf "%s" "$text" | wl-copy 2>/dev/null || printf "%s" "$text" | xclip -selection clipboard 2>/dev/null || true
    notify-send -t 2500 "ASR" "$text" 2>/dev/null || true
    echo "$text"
  else
    wl-copy <<< "$wav" 2>/dev/null || true
    notify-send -t 3000 "ASR saved" "$wav (offline)" 2>/dev/null || true
    echo "saved $wav (offline)"
  fi
}

case "${1:-}" in
  toggle)
    if is_recording; then
      stop_recording
    else
      start_recording
    fi
    ;;

  start)
    if is_recording; then
      echo "already recording"
      exit 0
    fi
    start_recording
    ;;

  stop)
    if ! is_recording; then
      echo "not recording"
      exit 0
    fi
    stop_recording
    ;;

  status)
    if is_recording; then
      local elapsed=""
      if [[ -f "$ASR_START_FILE" ]]; then
        elapsed=" $(( $(date +%s) - $(cat "$ASR_START_FILE") ))s elapsed"
      fi
      echo "recording${elapsed}"
    else
      echo "idle"
    fi
    ;;

  *) echo "usage: $0 {toggle|start|stop|status}"; exit 1;;
esac