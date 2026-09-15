# Claude Code → memory spine

Claude Pro can't be used by Hermes (needs Max + usage credits), so Claude is
reached through the Claude Code CLI — which joins the shared memory spine via
the same MCP server.

Add to `~/.claude.json` under `mcpServers`:

```json
{
  "mcpServers": {
    "memory": {
      "command": "python3",
      "args": ["$HOME/repos/agent-web/spine/mcp/server.py"],
      "env": {
        "MEM0_HOST": "http://localhost:8888",
        "MEM0_API_KEY": "<key from http://localhost:3000 wizard>",
        "MEMORY_USER_ID": "sean"
      }
    }
  }
}
```

Requires `pip3 install -r spine/mcp/requirements.txt` (or a venv — then point
`command` at its python).
