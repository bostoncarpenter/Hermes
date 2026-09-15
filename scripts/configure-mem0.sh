#!/bin/bash
# Point mem0 at the local Ollama server for LLM + embedder, via Ollama's
# OpenAI-compatible /v1 endpoint (mem0's `openai` provider honors openai_base_url).
# POST /configure deep-merges and persists overrides; requires admin key.
set -euo pipefail
ENV_FILE="$(cd "$(dirname "$0")/.." && pwd)/spine/.env"
set -a; . "$ENV_FILE"; set +a
: "${MEM0_API_KEY:?wizard key missing in spine/.env}"
OLLAMA_LLM_MODEL="${OLLAMA_LLM_MODEL:-qwen2.5:7b}"
OLLAMA_EMBED_MODEL="${OLLAMA_EMBED_MODEL:-nomic-embed-text}"
HOST="${MEM0_HOST:-http://localhost:8888}"
BASE="http://host.docker.internal:11434/v1"

curl -fsS -X POST "$HOST/configure" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $MEM0_API_KEY" \
  -d '{
    "llm":      {"provider": "openai", "config": {"model": "'"$OLLAMA_LLM_MODEL"'", "openai_base_url": "'"$BASE"'", "api_key": "ollama", "temperature": 0.2}},
    "embedder": {"provider": "openai", "config": {"model": "'"$OLLAMA_EMBED_MODEL"'", "openai_base_url": "'"$BASE"'", "api_key": "ollama", "embedding_dims": 768}}
  }'
echo
echo "mem0 now uses local Ollama (llm=$OLLAMA_LLM_MODEL, embedder=$OLLAMA_EMBED_MODEL/768d)."
