#!/usr/bin/env python3
"""Stdio MCP bridge to the self-hosted mem0 memory spine.

Env: MEM0_HOST (default http://localhost:8888), MEM0_API_KEY (required),
     MEMORY_USER_ID (default "sean").
"""
import os
import urllib.request
import urllib.error
import json

from mcp.server.fastmcp import FastMCP

HOST = os.environ.get("MEM0_HOST", "http://localhost:8888").rstrip("/")
API_KEY = os.environ.get("MEM0_API_KEY", "")
USER_ID = os.environ.get("MEMORY_USER_ID", "sean")

mcp = FastMCP("memory-spine")


def _req(method: str, path: str, payload: dict) -> dict:
    req = urllib.request.Request(
        HOST + path,
        data=json.dumps(payload).encode(),
        method=method,
        headers={"Content-Type": "application/json", "X-API-Key": API_KEY},
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        return {"error": f"{e.code}: {e.read().decode()[:500]}"}


@mcp.tool()
def remember(text: str) -> str:
    """Store a fact/preference/decision in shared long-term memory."""
    r = _req("POST", "/memories", {"messages": [{"role": "user", "content": text}],
                                   "user_id": USER_ID})
    return json.dumps(r)


@mcp.tool()
def recall(query: str, limit: int = 10) -> str:
    """Search shared long-term memory for facts relevant to the query."""
    r = _req("POST", "/search", {"query": query, "user_id": USER_ID, "limit": limit})
    return json.dumps(r)


if __name__ == "__main__":
    mcp.run()
