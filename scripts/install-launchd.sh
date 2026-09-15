#!/bin/bash
# Install the hermes-gateway launchd agent for the current user.
# Note: `hermes gateway install` (Hermes' own installer) also works on macOS.
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)/com.agentweb.hermes-gateway.plist"
DST="$HOME/Library/LaunchAgents/com.agentweb.hermes-gateway.plist"
mkdir -p "$HOME/Library/LaunchAgents"
cp "$SRC" "$DST"
launchctl unload "$DST" 2>/dev/null || true
launchctl load -w "$DST"
echo "Loaded. Check: hermes gateway status ; logs in /tmp/agentweb-hermes-gateway.*.log"
