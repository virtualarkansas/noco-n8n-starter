#!/bin/bash
# ============================================================
# NocoFlow Starter — Session Bootstrap Script
# ============================================================
# Runs automatically via SessionStart hook in .claude/settings.json
# every time the repo is opened in Claude Code.
#
# What it does:
#   1. Downloads n8n-mcp nodes.db (SQLite database with all n8n node docs)
#   2. Downloads n8n-skills (workflow pattern guidance files)
#   3. Makes all wrapper scripts executable
#   4. Reports status (stdout injected as Claude context)
#
# No server process needed — queries run directly via sqlite3 CLI.
# Idempotent — safe to run multiple times. Skips steps already done.
# ============================================================
set -euo pipefail
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
SKILLS_DIR="$PROJECT_DIR/.claude/skills"
SCRIPTS_DIR="$PROJECT_DIR/.claude/scripts"
DB_DIR="$PROJECT_DIR/data"
DB_FILE="$DB_DIR/nodes.db"
DB_URL="https://github.com/czlonkowski/n8n-mcp/raw/main/data/nodes.db"
# Track status
SKILLS_STATUS="❌ not installed"
DB_STATUS="❌ not available"
SCRIPTS_STATUS="❌ not found"
SQLITE_STATUS="❌ not found"
# ── 0. Check for sqlite3 ────────────────────────────────────
if command -v sqlite3 &>/dev/null; then
  SQLITE_STATUS="✅ $(sqlite3 --version 2>&1 | head -c 40)"
else
  SQLITE_STATUS="❌ sqlite3 not found — install with: apt-get install sqlite3"
fi
# ── 1. Download nodes.db if not present or empty ────────────
mkdir -p "$DB_DIR"
if [ ! -f "$DB_FILE" ] || [ ! -s "$DB_FILE" ]; then
  echo "Downloading n8n-mcp nodes.db (~50MB)..." >&2
  if curl -sL "$DB_URL" -o "$DB_FILE" 2>/dev/null; then
    # Verify it's a valid SQLite file
    if file "$DB_FILE" | grep -q "SQLite"; then
      NODE_COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM nodes;" 2>/dev/null || echo "0")
      DB_STATUS="✅ downloaded ($NODE_COUNT nodes)"
    else
      rm -f "$DB_FILE"
      DB_STATUS="❌ download corrupted — try again: bash scripts/install_pkgs.sh"
    fi
  else
    DB_STATUS="❌ download failed — check network access"
  fi
else
  # Already have the file, verify it
  if command -v sqlite3 &>/dev/null; then
    NODE_COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM nodes;" 2>/dev/null || echo "?")
    TMPL_COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM templates;" 2>/dev/null || echo "?")
    DB_STATUS="✅ ready ($NODE_COUNT nodes, $TMPL_COUNT templates)"
  else
    DB_STATUS="✅ file exists (install sqlite3 to query)"
  fi
fi
# ── 2. Download n8n-skills if not present ────────────────────
if [ ! -d "$SKILLS_DIR" ] || [ -z "$(ls -A "$SKILLS_DIR" 2>/dev/null)" ]; then
  echo "Downloading n8n-skills..." >&2
  mkdir -p "$SKILLS_DIR"
  if git clone --depth 1 --quiet https://github.com/czlonkowski/n8n-skills.git /tmp/n8n-skills 2>/dev/null; then
    cp /tmp/n8n-skills/dist/*.md "$SKILLS_DIR/" 2>/dev/null || true
    rm -rf /tmp/n8n-skills
  else
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
SKILL_COUNT=$(ls "$SKILLS_DIR"/*.md 2>/dev/null | wc -l || echo 0)
if [ "$SKILL_COUNT" -gt 0 ]; then
  SKILLS_STATUS="✅ $SKILL_COUNT skill files loaded"
else
  SKILLS_STATUS="⚠️ download failed — upload manually to .claude/skills/"
fi
# ── 3. Make scripts executable ───────────────────────────────
if [ -d "$SCRIPTS_DIR" ]; then
  chmod +x "$SCRIPTS_DIR"/*.sh 2>/dev/null || true
  SCRIPTS_STATUS="✅ ready"
fi
chmod +x "$PROJECT_DIR/scripts/"*.sh 2>/dev/null || true
chmod +x "$PROJECT_DIR/scripts/"*.js 2>/dev/null || true
# ── 4. Status report (stdout → Claude context) ──────────────
cat <<EOF
=== NocoFlow Starter — Session Ready ===

Environment:
  sqlite3:    $SQLITE_STATUS
  nodes.db:   $DB_STATUS
  n8n-skills: $SKILLS_STATUS
  Scripts:    $SCRIPTS_STATUS
  .env:       $([ -f "$PROJECT_DIR/.env" ] && echo "✅ configured" || echo "⚠️ not set — run: bash .claude/scripts/setup-env.sh <args>")

Available tools:
  bash .claude/scripts/mcp.sh search <query>         — search n8n nodes by keyword
  bash .claude/scripts/mcp.sh get <node_type>         — get full node documentation
  bash .claude/scripts/mcp.sh props <node_type>       — get node properties/params
  bash .claude/scripts/mcp.sh templates <query>       — search workflow templates
  bash .claude/scripts/mcp.sh stats                   — database statistics
  bash .claude/scripts/noco.sh <action> [args]        — NocoDB REST API
  bash .claude/scripts/n8n.sh <action> [args]         — n8n REST API

=== End Session Bootstrap ===
EOF
