#!/bin/bash
# Create the "Google ingest" cron job from hermes/prompts/google-ingest.md.
# Run AFTER `hermes mcp login gmail|gdrive|gcalendar` (fresh terminal).
set -euo pipefail
PROMPT_FILE="$(cd "$(dirname "$0")/.." && pwd)/hermes/prompts/google-ingest.md"
NAME="Google ingest"

hermes cron list || true
if hermes cron list 2>/dev/null | grep -qF "$NAME"; then
  echo "Job '$NAME' already exists — skipping."
  exit 0
fi

hermes cron create "every 6h" "$(cat "$PROMPT_FILE")" \
  --name "$NAME" --continuity --deliver telegram
echo "Created '$NAME' — summaries land on Telegram (TELEGRAM_HOME_CHANNEL)."
