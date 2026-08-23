#!/usr/bin/env zsh
# Minimal llama-cli launcher
# Maps models to ports: qwen/rwkv->8080(FIM), mini->8081(GEN), asr->8082(ASR)
set -uo pipefail

# --- Model config ---
FIM_PORT=8080
GEN_PORT=8081
ASR_PORT=8082

# --- Parse args ---
MODEL=""
KILL_FIRST=0
GPU_MODE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--model)
      if [[ $# -lt 2 ]]; then echo "Error: $1 requires an argument"; exit 1; fi
      MODEL="$2"; shift 2
      ;;
    -k|--kill) KILL_FIRST=1; shift ;;
    -g|--gpu)  GPU_MODE=1; shift ;;
    -c|--cpu)  GPU_MODE=0; shift ;;
    -h|--help) echo "Usage: $0 -m MODEL [-k] [-g|-c]\nModels:\n  qwen|rwkv  (FIM, port 8080, CPU default)\n  mini       (GEN, port 8081, GPU default)\n  asr       (ASR, port 8082, CPU default)\n\nFlags: -k kill first, -g force GPU (ngl=-1), -c force CPU (ngl=0)"; exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Validate ---
if [[ -z "$MODEL" ]]; then
  echo "Usage: $0 -m MODEL [-k] [-g|-c]"
  echo "Models: qwen|rwkv (FIM, port 8080, CPU default)
mini       (GEN, port 8081, GPU default)
asr       (ASR, port 8082, CPU default)"
  exit 1
fi

# --- Map model to port/ctx/ngl ---
case "$MODEL" in
  qwen|rwkv)  PORT=$FIM_PORT; CTX=16384; NGL=0;  CTK="f16"; CTT="f16" ;;
  mini)       PORT=$GEN_PORT; CTX=65536; NGL=-1; CTK="f16"; CTT="f16" ;;
  asr)        PORT=$ASR_PORT; CTX=16384; NGL=0;  CTK="f16"; CTT="f16" ;;
  *)          echo "Unknown model: $MODEL"; echo "Valid: qwen|rwkv|mini|asr"; exit 1 ;;
esac

# Apply GPU/CPU override if requested (-g forces all layers GPU, -c forces CPU)
if [[ "$GPU_MODE" == "1" ]]; then NGL=-1; elif [[ "$GPU_MODE" == "0" ]]; then NGL=0; fi

# --- Kill existing if requested or in use ---
kill_port() {
  local p=$1
  local pid
  pid=$(ss -tlnp 2>/dev/null | grep ":${p}" | grep -oE 'pid=[0-9]+' | head -n1 | cut -d= -f2)
  pid=${pid//[!0-9]/}
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null || true
    sleep 1
  fi
}

if [[ "$KILL_FIRST" == "1" ]] || ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
  echo "Killing existing server on port $PORT ..."
  kill_port $PORT
fi

# --- Launch ---
LLAMA_BIN="${LLAMA_BIN:-$(command -v llama-server 2>/dev/null || echo /run/current-system/sw/bin/llama-server)}"
MODEL_PATH=""
EXTRA_ARGS=()
case $MODEL in
  qwen)   MODEL_PATH="$HOME/models/Qwen2.5-Coder-3B-Instruct-Q4_K_L.gguf" ;;
  rwkv)   MODEL_PATH="$HOME/models/rwkv7-g1g-2.9b-Q4_K_M.gguf" ;;
  mini)   MODEL_PATH="$HOME/models/MiniCPM5-1B-Claude-Opus-Fable5-Thinking-Q8_0.gguf" ;;
  asr)    MODEL_PATH="$HOME/models/Qwen3-ASR-0.6B-Q8_0.gguf"
          EXTRA_ARGS+=(--mmproj "$HOME/models/mmproj-Qwen3-ASR-0.6B-Q8_0.gguf") ;;
esac

if [[ ! -f "$MODEL_PATH" ]]; then
  echo "Model not found: $MODEL_PATH"
  exit 1
fi

echo "→ launching $MODEL on port $PORT ctx=$CTX ngl=$NGL ..."
"$LLAMA_BIN" --model "$MODEL_PATH" --port "$PORT" --ctx-size "$CTX" -ngl "$NGL" -ctk "$CTK" -ctv "$CTT" "${EXTRA_ARGS[@]}" > "/home/ryan/models/Logs/${MODEL}.log" 2>&1 &
SERVER_PID=$!

echo "launched $MODEL on :$PORT ctx=$CTX ngl=$NGL"
echo "Logs: /home/ryan/models/Logs/${MODEL}.log"

# Brief wait + check (retry health for up to 10s)
tries=0
while (( tries < 50 )); do
  if curl -sf --max-time 2 "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
    echo "Server running on :$PORT"
    break
  fi
  # check if process died early
  if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo "WARNING: Server exited. Check /home/ryan/models/Logs/${MODEL}.log"
    break
  fi
  sleep 0.2
  (( tries++ ))
done
if (( tries == 50 )); then
  echo "WARNING: Server may not have started after 10s. Check /home/ryan/models/Logs/${MODEL}.log"
fi
