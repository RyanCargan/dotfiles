#!/usr/bin/env zsh
# ASR hold-to-record for Hyprland bind/bindr
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
      "$ASR_WAV" &
    echo $! > "$ASR_PID_FILE"
    notify-send -t 800 "ASR" "● recording..." 2>/dev/null || true
    ;;

  stop)
    pid=$(cat "$ASR_PID_FILE" 2>/dev/null)
    if [[ -n "$pid" ]]; then
      kill "$pid" 2>/dev/null
      wait "$pid" 2>/dev/null || true
      rm -f "$ASR_PID_FILE"
    fi

    if [[ ! -f "$ASR_WAV" ]]; then
      notify-send -t 1500 "ASR" "no audio" 2>/dev/null
      exit 1
    fi

    # Wait for ffmpeg flush
    sleep 0.5

    # Send WAV directly to ASR endpoint
    text=$(curl -sf --max-time 60 \
      -F file=@"$ASR_WAV" \
      -F model=qwen3-asr \
      -F response_format=json \
      "http://127.0.0.1:$PORT_ASR/v1/audio/transcriptions" 2>/dev/null \
      | jq -r '.text // empty' 2>/dev/null)

    # Strip Qwen3-ASR wrapper: "language English<asr_text>actual text"
    text=${text#*<asr_text>}

    if [[ -n "$text" ]]; then
      printf "%s" "$text" | wl-copy 2>/dev/null || printf "%s" "$text" | xclip -selection clipboard 2>/dev/null || true
      notify-send -t 2500 "ASR → clipboard" "$text" 2>/dev/null || true
      echo "$text"
    else
      # Fallback: archive opus (1 of 10 slots)
      idx=$(cat "$ASR_IDX_FILE" 2>/dev/null || echo 0)
      idx=$(( idx % 10 ))
      opus="$AUDIO_DIR/asr-${idx}.opus"
      ffmpeg -hide_banner -loglevel error -y -i "$ASR_WAV" -c:a libopus -b:a 24k -vbr on "$opus" 2>/dev/null || cp "$ASR_WAV" "$opus"
      echo $(( (idx + 1) % 10 )) > "$ASR_IDX_FILE"
      wl-copy <<< "$opus" 2>/dev/null || true
      notify-send -t 3000 "ASR saved" "$opus (offline)" 2>/dev/null || true
      echo "saved $opus (offline)"
    fi
    ;;

  *) echo "usage: $0 {start|stop}"; exit 1;;
esac