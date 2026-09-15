# agent-web

Deployable kit for a 24/7 Mac mini: [Hermes Agent](https://hermes-agent.nousresearch.com)
orchestrates every AI subscription on top of a shared mem0 memory spine.

```
                 Telegram (phone)          Terminal / SSH
                        │                        │
                        ▼                        ▼
                ┌───────────────────────────────────────┐
                │   Hermes Agent (orchestrator, launchd) │
                │   default: Nous Portal                 │
                │   fallback: openai-codex → xai-oauth   │
                └───────────────┬───────────────────────┘
                                │ MCP (stdio)
        ┌───────────────┬───────┴────────┬──────────────┐
        ▼               ▼                ▼              ▼
   Claude Code      Codex CLI       Gemini CLI     Hermes
   (Claude Pro)     (ChatGPT)       (API key)      (Nous/Grok…)
        └───────────────┴───────┬────────┴──────────────┘
                                ▼
                    spine/mcp/server.py  (remember/recall)
                                │ X-API-Key
                                ▼
   docker: mem0 api :8888 ── postgres+pgvector ── dashboard :3000 ── open-webui :8080
                        │
                        ▼  OpenAI-compatible /v1 (host.docker.internal)
              native Ollama :11434  (Metal GPU — extraction never leaves the Mac)
```

## What each subscription can / can't do

| Subscription | Wired as | Notes |
|---|---|---|
| Nous Portal | default provider `nous` via `hermes model` | also bundles tools (TTS, web) |
| ChatGPT | provider `openai-codex`, `hermes auth add openai-codex` | first fallback |
| SuperGrok | provider `xai-oauth`, `hermes auth add xai-oauth` | second fallback |
| Gemini | via Nous Portal models, or the Gemini CLI client | no API key needed by Hermes |
| Claude Pro | **not usable by Hermes** (needs Max + extra credits) | reached via Claude Code CLI, which joins the spine via `spine/mcp` |

## What each subscription pays for

| Subscription | Billing notes |
|---|---|
| Nous Portal | Covers the default model; also bundles tool providers (TTS, web). |
| ChatGPT → openai-codex | OAuth login; Hermes does not document quota semantics — expect ChatGPT plan limits. |
| SuperGrok → xai-oauth | Uses subscription quota. |
| Memory extraction | Local Ollama (qwen2.5 + nomic-embed-text) — free, no memory content leaves the Mac. |
| Claude Pro | Not usable in Hermes (needs Max + extra usage credits) — Claude Code CLI only. |

## Quickstart (≈10 min, macOS)

```bash
git clone <this repo> ~/repos/agent-web && cd ~/repos/agent-web
bash scripts/setup-mac.sh          # brew, docker (OrbStack), hermes, configs, docker compose up
                                   # (first `up` builds mem0 API + dashboard from source — a few minutes)
# then, as prompted:
open http://localhost:3000         # mem0 wizard → API key → spine/.env + ~/.hermes/.env
bash scripts/configure-mem0.sh     # point mem0 at local Ollama (llm+embedder)
# smoke test:
curl -s -H "X-API-Key: $MEM0_API_KEY" -X POST localhost:8888/search \
  -H 'content-type: application/json' -d '{"query":"test","user_id":"sean"}'
hermes auth add openai-codex
hermes auth add xai-oauth
hermes model                       # Nous Portal default
hermes gateway setup               # Telegram
bash scripts/install-launchd.sh    # or: hermes gateway install
```

## Mobile usage

Telegram bot → `hermes gateway` (always-on via launchd, KeepAlive). Same
agent, same memory: text, voice memos (auto-transcribed), files, group chats.

## How memory flows

Every client (Hermes, Claude Code, Codex, Gemini CLI) loads `spine/mcp/server.py`
as a stdio MCP server exposing `remember(text)` / `recall(query)`. Both call the
mem0 REST API (`/memories`, `/search`, `X-API-Key`) on `localhost:8888` with one
`user_id` — so a preference stored by Claude Code is retrievable by Hermes over
Telegram. Hermes additionally sets `memory.provider: mem0` (self-hosted via
`MEM0_HOST`/`MEM0_API_KEY`) for its native memory.

Memory extraction runs locally on Ollama — no memory content leaves the Mac.
`qwen2.5:7b` wants ~8GB free RAM; on an 8GB mini set `OLLAMA_LLM_MODEL=qwen2.5:3b`
in `spine/.env`. Browse the memory log in the mem0 dashboard at :3000. Open
WebUI (:8080) is an optional desktop chat view over the same local Ollama — it
is not wired into the memory API.

## Layout

```
spine/            docker-compose (postgres/pgvector, mem0 api*, dashboard*, open-webui)
                  *mem0 api + dashboard build from pinned upstream SHA (MEM0_REF in spine/.env)
spine/mcp/        stdio MCP memory bridge (FastMCP)
hermes/           config.yaml + env.example → copied to ~/.hermes/
clients/          drop-in MCP snippets for claude-code, codex, gemini-cli
scripts/          setup-mac.sh, launchd plist + installer
```
