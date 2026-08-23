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

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--model)    MODEL="$2"; shift 2 || exit 1 ;;
    -k|--kill)     KILL_FIRST=1 ;;
    -h|--help)     echo "Usage: $0 -m MODEL [-k]\nModels: qwen|rwkv (FIM, port 8080)\n             mini       (GEN, port 8081)\n             asr       (ASR, port 8082)"; exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

# --- Validate ---
if [[ -z "$MODEL" ]]; then
  echo "Usage: $0 -m MODEL [-k]"
  echo "Models: qwen|rwkv (FIM, port 8080)
mini       (GEN, port 8081)
asr       (ASR, port 8082)"
  exit 1
fi

# --- Map model to port/ctx/ngl ---
case "$MODEL" in
  qwen|rwkv)  PORT=$FIM_PORT; CTX=16384; NGL=-1; CTK="f16"; CTT="f16" ;;
  mini)       PORT=$GEN_PORT; CTX=65536; NGL=0;   CTK="f16"; CTT="f16" ;;
  asr)        PORT=$ASR_PORT; CTX=16384; NGL=0;   CTK="f16"; CTT="f16" ;;
  *)          echo "Unknown model: $MODEL"; echo "Valid: qwen|rwkv|mini|asr"; exit 1 ;;
esac

# --- Kill existing if requested or in use ---
kill_port() {
  local p=$1
  local pid
  pid=$(ss -tlnp 2>/dev/null | grep -E "127\.0\.0\.1:\"$p\|:\"$p" | grep -oE 'pid=[0-9]+' | head -n1 | cut -d= -f2)
  pid=${pid//[!0-9]/}
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null || true
  fi
}

if [[ "$KILL_FIRST" == "1" ]] || ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
  echo "Killing existing server on port $PORT ..."
  kill_port $PORT
fi

# --- Launch ---
LLAMA_BIN="${LLAMA_BIN:-$(command -v llama-server 2>/dev/null || echo /run/current-system/sw/bin/llama-server)}"
MODEL_PATH=""
case $MODEL in
  qwen)   MODEL_PATH="$HOME/models/Qwen2.5-Coder-3B-Instruct-Q4_K_L.gguf" ;;
  rwkv)   MODEL_PATH="$HOME/models/rwkv7-g1g-2.9b-Q4_K_M.gguf" ;;
  mini)   MODEL_PATH="$HOME/models/MiniCPM5-1B-Claude-Opus-Fable5-Thinking-Q8_0.gguf" ;;
  asr)    MODEL_PATH="$HOME/models/Qwen3-ASR-0.6B-Q8_0.gguf" ;;
esac

if [[ ! -f "$MODEL_PATH" ]]; then
  echo "Model not found: $MODEL_PATH"
  exit 1
fi

echo "→ launching $MODEL on port $PORT ctx=$CTX ngl=$NGL ..."
"$LLAMA_BIN" --model "$MODEL_PATH" --port "$PORT" --ctx-size "$CTX" -ngl "$NGL" -ctk "$CTK" -ctv "$CTT" > "/home/ryan/models/Logs/${MODEL}.log" 2>&1 &

echo "launched $MODEL on :$PORT ctx=$CTX ngl=$NGL"
echo "Logs: /home/ryan/models/Logs/${MODEL}.log"

# Brief wait + check
sleep 1
if ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
  echo "Server running on :$PORT"
else
  echo "WARNING: Server may not have started. Check /home/ryan/models/Logs/${MODEL}.log"
fi