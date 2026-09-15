#!/bin/bash
# Idempotent setup for agent-web on macOS. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
HERMES_DIR="$HOME/.hermes"

echo "==> Homebrew"
if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "==> Docker runtime"
if ! docker info >/dev/null 2>&1; then
  command -v docker >/dev/null || brew install --cask orbstack
  open -a OrbStack 2>/dev/null || open -a Docker 2>/dev/null || true
  echo "    Waiting for docker daemon..."
  until docker info >/dev/null 2>&1; do sleep 2; done
fi

echo "==> Hermes Agent"
command -v hermes >/dev/null || curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

echo "==> MCP server deps"
python3 -m pip install --user -r "$ROOT/spine/mcp/requirements.txt"

echo "==> Configs (existing files backed up to *.bak.<ts>)"
mkdir -p "$HERMES_DIR"
backup_copy() { # src dst
  [ -f "$2" ] && cp "$2" "$2.bak.$(date +%s)"
  cp "$1" "$2"
}
backup_copy "$ROOT/hermes/config.yaml" "$HERMES_DIR/config.yaml"
[ -f "$HERMES_DIR/.env" ] || cp "$ROOT/hermes/env.example" "$HERMES_DIR/.env"
if [ ! -f "$ROOT/spine/.env" ]; then
  cp "$ROOT/spine/.env.example" "$ROOT/spine/.env"
  sed -i '' "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$(openssl rand -hex 32)/" "$ROOT/spine/.env"
  sed -i '' "s/^JWT_SECRET=.*/JWT_SECRET=$(openssl rand -hex 32)/" "$ROOT/spine/.env"
  echo "    generated POSTGRES_PASSWORD + JWT_SECRET in spine/.env"
fi

echo "==> Spine stack"
docker compose -f "$ROOT/spine/docker-compose.yml" --env-file "$ROOT/spine/.env" up -d || \
  echo "!! fill in spine/.env first (GOOGLE_API_KEY)"

cat <<'EOF'

Done. Next steps:
  1. Fill in spine/.env (GOOGLE_API_KEY; passwords were auto-generated),
     then re-run this script if the stack didn't come up.
  2. Open http://localhost:3000 → run the wizard → copy the API key into
     spine/.env (MEM0_API_KEY) and ~/.hermes/.env (MEM0_API_KEY).
  2b. Smoke test: curl -s -H "X-API-Key: $MEM0_API_KEY" -X POST \
      localhost:8888/search -H 'content-type: application/json' \
      -d '{"query":"test","user_id":"sean"}'
  3. Log subscriptions into Hermes:
       hermes auth add openai-codex   # ChatGPT
       hermes auth add xai-oauth      # SuperGrok
       hermes model                   # pick Nous Portal as default
     Add GEMINI_API_KEY to ~/.hermes/.env.
  3b. Switch mem0 to Gemini (default is OpenAI):
       bash scripts/configure-mem0.sh
  4. Telegram: hermes gateway setup, then scripts/install-launchd.sh
     (or simply `hermes gateway install` — Hermes can self-install on launchd).
  5. Wire Claude Code / Codex / Gemini CLI via clients/ snippets.
EOF
