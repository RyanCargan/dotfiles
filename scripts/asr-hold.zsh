#!/usr/bin/env zsh
# ASR hold-to-record helper for Hyprland bind/bindr
# Start: asr-hold.zsh start   Stop: asr-hold.zsh stop
set -uo pipefail
AUDIO_DIR="${AUDIO_DIR:-$HOME/models/Audio}"
ASR_WAV="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/asr-hold.wav"
ASR_PID_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/asr-rec.pid"
ASR_IDX_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/asr-idx"
PORT_ASR="${PORT_ASR:-8082}"
case "${1:-}" in
  start)
    mkdir -p "$AUDIO_DIR" 2>/dev/null
    # ensure Easy Effects Source is default for persistence (optional: wpctl set-default 77)
    id=$(wpctl status 2>/dev/null | grep -oP '\d+(?=\.\s+Easy Effects Source)' | head -n1); id=${id:-77}
    wpctl set-default "$id" 2>/dev/null || true
    target="Easy Effects Source"
    if command -v pw-record >/dev/null 2>&1; then
      pw-record --target "$target" "$ASR_WAV" & echo $! > "$ASR_PID_FILE"
    else
      ffmpeg -hide_banner -loglevel error -f pulse -i "$target" -ac 1 -ar 16000 "$ASR_WAV" -y & echo $! > "$ASR_PID_FILE"
    fi
    notify-send -t 800 "ASR" "● recording..." 2>/dev/null || true
    ;;
  stop)
    pid=$(cat "$ASR_PID_FILE" 2>/dev/null)
    if [[ -n "$pid" ]]; then kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null || true; rm -f "$ASR_PID_FILE"; fi
    if [[ ! -f "$ASR_WAV" ]]; then notify-send -t 1500 "ASR" "no audio" 2>/dev/null; exit 1; fi
    idx=$(cat "$ASR_IDX_FILE" 2>/dev/null || echo 0); idx=$(( idx % 10 ))
    opus="$AUDIO_DIR/asr-${idx}.opus"
    ffmpeg -hide_banner -loglevel error -i "$ASR_WAV" -c:a libopus -b:a 24k -vbr on -compression_level 10 "$opus" -y 2>/dev/null || cp "$ASR_WAV" "$opus"
    echo $(( (idx + 1) % 10 )) > "$ASR_IDX_FILE"
    text=""
    # WAV upload first: this llama-server build routes non-wav through the image
    # decoder (mtmd) and fails/garbles ("language None"); opus stays archive-only.
    text=$(curl -sf --max-time 60 -F file=@"$ASR_WAV" -F model=qwen3-asr "http://127.0.0.1:$PORT_ASR/v1/audio/transcriptions" 2>/dev/null | jq -r '.text // empty' 2>/dev/null)
    if [[ -z "$text" ]]; then
      text=$(curl -sf --max-time 60 -F file=@"$opus" -F model=qwen3-asr "http://127.0.0.1:$PORT_ASR/v1/audio/transcriptions" 2>/dev/null | jq -r '.text // empty' 2>/dev/null)
    fi
    if [[ -n "$text" ]]; then
      printf "%s" "$text" | wl-copy 2>/dev/null || printf "%s" "$text" | xclip -selection clipboard 2>/dev/null || true
      notify-send -t 2500 "ASR → clipboard" "$text" 2>/dev/null || true
      echo "$text"
    else
      wl-copy <<< "$opus" 2>/dev/null || true
      notify-send -t 3000 "ASR saved" "$opus (ASR offline — slot a)" 2>/dev/null || true
      echo "saved $opus (slot a offline)"
    fi
    ;;
  *) echo "usage: $0 {start|stop}"; exit 1;;
esac
