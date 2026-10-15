#!/bin/sh
# Configure AI MCP servers (Claude ~/.claude.json + Codex executor).
# PLANE_API_KEY resolution (first match wins):
#   1. $HOME/.config/ai-mcp/plane.env  (untracked; PLANE_API_KEY=...)
#   2. bitwarden: bw get password <BW_ITEM> (vault must be unlocked / BW_SESSION set)
# Safe to re-run: only inserts missing servers, never overwrites existing.
set -eu
BW_ITEM="Plane MCP API Key"

if [ -f "$HOME/.config/ai-mcp/plane.env" ]; then
    . "$HOME/.config/ai-mcp/plane.env"
fi
if [ -z "${PLANE_API_KEY:-}" ]; then
    PLANE_API_KEY=$(bw get password "$BW_ITEM" 2>/dev/null) || PLANE_API_KEY=""
fi

# --- Claude: merge mcpServers into ~/.claude.json ---
if [ -z "${PLANE_API_KEY:-}" ]; then
    echo "WARNING: PLANE_API_KEY not found; plane MCP server will be skipped." >&2
    python3 - <<'PYINNER'
import json, os
mcp = {
  "executor": {
    "command": "executor",
    "args": [
      "mcp"
    ]
  },
  "browser": {
    "type": "stdio",
    "command": "npx",
    "args": [
      "-y",
      "@playwright/mcp@latest",
      "--browser=chromium",
      "--caps=pdf,vision,devtools"
    ],
    "env": {}
  },
  "whatsapp": {
    "type": "stdio",
    "command": "node",
    "args": [
      "/home/polynux/.local/share/whatsapp-mcp-plus/src/dist/index.js"
    ],
    "env": {
      "WAMCP_MODE": "read-only",
      "WAMCP_DATA_DIR": "/home/polynux/.local/share/whatsapp-mcp-plus/data",
      "WAMCP_AUTH_DIR": "/home/polynux/.local/share/whatsapp-mcp-plus/auth_info",
      "WAMCP_SCOPES": "read,analytics,media"
    }
  }
}
p = os.path.expanduser("~/.claude.json")
d = json.load(open(p)) if os.path.exists(p) else {}
have = d.setdefault("mcpServers", {})
added = [k for k in mcp if k not in have]
have.update(mcp)
json.dump(d, open(p, "w"), indent=2)
print("claude mcp: added", added or "nothing (already present)")
PYINNER
else
    export PLANE_API_KEY
    python3 - <<'PYINNER'
import json, os
mcp = {
  "executor": {
    "command": "executor",
    "args": [
      "mcp"
    ]
  },
  "browser": {
    "type": "stdio",
    "command": "npx",
    "args": [
      "-y",
      "@playwright/mcp@latest",
      "--browser=chromium",
      "--caps=pdf,vision,devtools"
    ],
    "env": {}
  },
  "plane": {
    "type": "stdio",
    "command": "uvx",
    "args": [
      "plane-mcp-server",
      "stdio"
    ],
    "env": {
      "PLANE_BASE_URL": "http://plane.local",
      "PLANE_WORKSPACE_SLUG": "polynux",
      "PLANE_API_KEY": "__PLANE_API_KEY__"
    }
  },
  "whatsapp": {
    "type": "stdio",
    "command": "node",
    "args": [
      "/home/polynux/.local/share/whatsapp-mcp-plus/src/dist/index.js"
    ],
    "env": {
      "WAMCP_MODE": "read-only",
      "WAMCP_DATA_DIR": "/home/polynux/.local/share/whatsapp-mcp-plus/data",
      "WAMCP_AUTH_DIR": "/home/polynux/.local/share/whatsapp-mcp-plus/auth_info",
      "WAMCP_SCOPES": "read,analytics,media"
    }
  }
}
p = os.path.expanduser("~/.claude.json")
d = json.load(open(p)) if os.path.exists(p) else {}
have = d.setdefault("mcpServers", {})
added = [k for k in mcp if k not in have]
mcp["plane"]["env"]["PLANE_API_KEY"] = os.environ["PLANE_API_KEY"]
have.update(mcp)
json.dump(d, open(p, "w"), indent=2)
print("claude mcp: added", added or "nothing (already present)")
PYINNER
fi

# --- Codex: add [mcp_servers.executor] if missing ---
CFG="$HOME/.codex/config.toml"
if [ -f "$CFG" ] && grep -q "^\[mcp_servers.executor\]" "$CFG"; then
    echo "codex mcp: executor already present"
else
    mkdir -p "$(dirname "$CFG")"
    touch "$CFG"
    printf '\n[mcp_servers.executor]\ncommand = "executor"\nargs = [ "mcp" ]\n' >> "$CFG"
    echo "codex mcp: executor added"
fi
