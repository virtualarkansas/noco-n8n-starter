#!/bin/bash
# ============================================================
# NocoFlow Starter — Session Bootstrap Script
# ============================================================
# Runs automatically via SessionStart hook in .claude/settings.json
# every time the repo is opened in Claude Code.
#
# What it does:
#   1. Installs n8n-mcp globally (node documentation + validation server)
#   2. Downloads n8n-skills to .claude/skills/ (workflow pattern guides)
#   3. Starts the n8n-mcp HTTP server on localhost:3001
#   4. Makes all wrapper scripts executable
#   5. Reports status (stdout injected as Claude context)
#
# Idempotent — safe to run multiple times. Skips steps already done.
# ============================================================

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
SKILLS_DIR="$PROJECT_DIR/.claude/skills"
SCRIPTS_DIR="$PROJECT_DIR/.claude/scripts"
MCP_PORT=3001
MCP_PID_FILE="/tmp/n8n-mcp.pid"

# Track status for the report
SKILLS_STATUS="❌ not installed"
MCP_STATUS="❌ not running"
SCRIPTS_STATUS="❌ not found"

# ── 1. Install n8n-mcp if not already available ─────────────

if ! command -v n8n-mcp &>/dev/null; then
  echo "Installing n8n-mcp globally..." >&2
  npm install -g n8n-mcp --silent 2>/dev/null || {
    echo "Global install failed, will fall back to npx..." >&2
    true
  }
fi

# ── 2. Download n8n-skills if not already present ────────────

if [ ! -d "$SKILLS_DIR" ] || [ -z "$(ls -A "$SKILLS_DIR" 2>/dev/null)" ]; then
  echo "Downloading n8n-skills..." >&2
  mkdir -p "$SKILLS_DIR"

  # Try git clone first (fastest)
  if git clone --depth 1 --quiet https://github.com/czlonkowski/n8n-skills.git /tmp/n8n-skills 2>/dev/null; then
    cp /tmp/n8n-skills/dist/*.md "$SKILLS_DIR/" 2>/dev/null || true
    rm -rf /tmp/n8n-skills
  else
    # Fallback: download individual files via raw GitHub URLs
    echo "Git clone failed, trying individual downloads..." >&2
    SKILLS_BASE="https://raw.githubusercontent.com/czlonkowski/n8n-skills/main/dist"
    for file in \
      "01-expression-syntax.md" \
      "02-mcp-tools-expert.md" \
      "03-workflow-patterns.md" \
      "04-validation-expert.md" \
      "05-node-configuration.md" \
      "06-code-javascript.md" \
      "07-code-python.md"; do
      curl -sL "$SKILLS_BASE/$file" -o "$SKILLS_DIR/$file" 2>/dev/null || true
    done
  fi
fi

# Check skills result
SKILL_COUNT=$(ls "$SKILLS_DIR"/*.md 2>/dev/null | wc -l || echo 0)
if [ "$SKILL_COUNT" -gt 0 ]; then
  SKILLS_STATUS="✅ $SKILL_COUNT skill files loaded"
else
  SKILLS_STATUS="⚠️ download failed — upload manually to .claude/skills/"
fi

# ── 3. Make all scripts executable ───────────────────────────

if [ -d "$SCRIPTS_DIR" ]; then
  chmod +x "$SCRIPTS_DIR"/*.sh 2>/dev/null || true
  SCRIPTS_STATUS="✅ ready"
fi

chmod +x "$PROJECT_DIR/scripts/"*.sh 2>/dev/null || true
chmod +x "$PROJECT_DIR/scripts/"*.js 2>/dev/null || true

# ── 4. Start n8n-mcp HTTP server if not already running ─────

if curl -s "http://localhost:$MCP_PORT/health" >/dev/null 2>&1; then
  MCP_STATUS="✅ already running on port $MCP_PORT"
else
  # Kill stale process
  if [ -f "$MCP_PID_FILE" ]; then
    kill "$(cat "$MCP_PID_FILE")" 2>/dev/null || true
    rm -f "$MCP_PID_FILE"
  fi

  # Source n8n config if available (enables management tools)
  if [ -f "$PROJECT_DIR/.env" ]; then
    export $(grep -E '^(N8N_URL|N8N_API_KEY)' "$PROJECT_DIR/.env" | xargs) 2>/dev/null || true
    [ -n "${N8N_URL:-}" ] && export N8N_API_URL="$N8N_URL"
  fi

  export MCP_MODE=http
  export PORT=$MCP_PORT
  export LOG_LEVEL=error
  export DISABLE_CONSOLE_OUTPUT=true
  export N8N_MCP_TELEMETRY_DISABLED=true

  if command -v n8n-mcp &>/dev/null; then
    n8n-mcp &>/dev/null &
  else
    npx -y n8n-mcp &>/dev/null &
  fi
  echo $! > "$MCP_PID_FILE"

  # Wait up to 60 seconds
  for i in $(seq 1 60); do
    if curl -s "http://localhost:$MCP_PORT/health" >/dev/null 2>&1; then
      MCP_STATUS="✅ running on port $MCP_PORT (1,084 nodes, 2,646 templates)"
      [ -n "${N8N_API_URL:-}" ] && MCP_STATUS="$MCP_STATUS + management tools"
      break
    fi
    sleep 1
  done

  # Final check
  if ! curl -s "http://localhost:$MCP_PORT/health" >/dev/null 2>&1; then
    MCP_STATUS="⚠️ failed to start — run 'bash .claude/scripts/start-mcp.sh' manually"
  fi
fi

# ── 5. Status report (stdout → Claude context) ──────────────

cat <<EOF
=== NocoFlow Starter — Session Ready ===

Environment:
  n8n-skills: $SKILLS_STATUS
  n8n-mcp:    $MCP_STATUS
  Scripts:    $SCRIPTS_STATUS
  .env:       $([ -f "$PROJECT_DIR/.env" ] && echo "✅ configured" || echo "⚠️ not set — run: bash .claude/scripts/setup-env.sh <args>")

Available tools:
  bash .claude/scripts/mcp.sh <tool> '<json>'    — query n8n node docs
  bash .claude/scripts/noco.sh <action> [args]   — NocoDB REST API
  bash .claude/scripts/n8n.sh <action> [args]    — n8n REST API

Quick reference:
  mcp.sh search_nodes '{"query":"webhook"}'
  mcp.sh get_node '{"nodeType":"n8n-nodes-base.webhook","detail":"standard"}'
  noco.sh list-tables
  n8n.sh list-workflows

=== End Session Bootstrap ===
EOF
