#!/bin/bash
# Point mem0 at Gemini for LLM + embedder (defaults are OpenAI).
# Run after the :3000 wizard has issued an admin API key into spine/.env.
# POST /configure deep-merges and persists overrides; requires admin key.
set -euo pipefail
ENV_FILE="$(cd "$(dirname "$0")/.." && pwd)/spine/.env"
set -a; . "$ENV_FILE"; set +a
: "${MEM0_API_KEY:?wizard key missing in spine/.env}"
: "${GOOGLE_API_KEY:?missing in spine/.env}"
HOST="${MEM0_HOST:-http://localhost:8888}"

curl -fsS -X POST "$HOST/configure" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $MEM0_API_KEY" \
  -d '{
    "llm":      {"provider": "gemini", "config": {"api_key": "'"$GOOGLE_API_KEY"'", "model": "gemini-2.5-flash", "temperature": 0.2}},
    "embedder": {"provider": "gemini", "config": {"api_key": "'"$GOOGLE_API_KEY"'", "model": "models/gemini-embedding-001", "embedding_dims": 768}}
  }'
echo
echo "mem0 now uses Gemini (llm=gemini-2.5-flash, embedder=gemini-embedding-001/768d)."
