#!/bin/bash
# ============================================================
# n8n Node Documentation — SQLite Query Interface
# ============================================================
# Queries the n8n-mcp nodes.db database directly with sqlite3.
# No server needed — all data is in the pre-built SQLite file.
#
# Usage:
#   mcp.sh search <query>              Search nodes by keyword
#   mcp.sh get <node_type>             Full node documentation
#   mcp.sh props <node_type>           Node properties/parameters
#   mcp.sh ops <node_type>             Node operations
#   mcp.sh templates <query>           Search workflow templates
#   mcp.sh template-nodes <id>         Get template node list
#   mcp.sh categories                  List all node categories
#   mcp.sh stats                       Database statistics
#   mcp.sh sql '<raw_query>'           Run arbitrary SQL (advanced)
# ============================================================
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
DB_FILE="${PROJECT_DIR}/data/nodes.db"
if [ ! -f "$DB_FILE" ]; then
  echo "❌ nodes.db not found at $DB_FILE"
  echo "Run: bash scripts/install_pkgs.sh"
  exit 1
fi
if ! command -v sqlite3 &>/dev/null; then
  echo "❌ sqlite3 not found. Install with: apt-get install sqlite3"
  exit 1
fi
ACTION="$1"
shift 2>/dev/null || true
QUERY="$*"

# Normalize node_type: the DB stores "nodes-base.webhook" not "n8n-nodes-base.webhook"
# Accept either format for get/props/ops commands
normalize_node_type() {
  local nt="$1"
  # Try exact match first
  local found=$(sqlite3 "$DB_FILE" "SELECT node_type FROM nodes WHERE node_type = '${nt}' LIMIT 1;")
  if [ -n "$found" ]; then
    echo "$found"
    return
  fi
  # Strip 'n8n-' prefix and retry
  local stripped="${nt#n8n-}"
  found=$(sqlite3 "$DB_FILE" "SELECT node_type FROM nodes WHERE node_type = '${stripped}' LIMIT 1;")
  if [ -n "$found" ]; then
    echo "$found"
    return
  fi
  # Return original (will produce empty results, but that's the user's typo)
  echo "$nt"
}

case "$ACTION" in
  search)
    # Full-text search across node types, names, descriptions
    if [ -z "$QUERY" ]; then
      echo "Usage: mcp.sh search <query>"
      echo "Example: mcp.sh search webhook"
      exit 1
    fi
    sqlite3 -header -column "$DB_FILE" \
      "SELECT node_type, display_name, category,
              SUBSTR(description, 1, 120) AS description
       FROM nodes
       WHERE node_type IN (
         SELECT node_type FROM nodes_fts WHERE nodes_fts MATCH '${QUERY}'
       )
       ORDER BY display_name
       LIMIT 30;"
    ;;
  get)
    # Full node documentation
    if [ -z "$QUERY" ]; then
      echo "Usage: mcp.sh get <node_type>"
      echo "Example: mcp.sh get n8n-nodes-base.webhook"
      exit 1
    fi
    NODE_TYPE=$(normalize_node_type "$QUERY")
    sqlite3 -header -column "$DB_FILE" \
      "SELECT node_type, display_name, category, description,
              documentation, ai_documentation_summary
       FROM nodes
       WHERE node_type = '${NODE_TYPE}';"
    ;;
  props)
    # Node properties / parameter schema
    if [ -z "$QUERY" ]; then
      echo "Usage: mcp.sh props <node_type>"
      echo "Example: mcp.sh props n8n-nodes-base.httpRequest"
      exit 1
    fi
    NODE_TYPE=$(normalize_node_type "$QUERY")
    sqlite3 "$DB_FILE" \
      "SELECT properties_schema FROM nodes WHERE node_type = '${NODE_TYPE}';"
    ;;
  ops)
    # Node operations
    if [ -z "$QUERY" ]; then
      echo "Usage: mcp.sh ops <node_type>"
      echo "Example: mcp.sh ops n8n-nodes-base.httpRequest"
      exit 1
    fi
    NODE_TYPE=$(normalize_node_type "$QUERY")
    sqlite3 "$DB_FILE" \
      "SELECT operations FROM nodes WHERE node_type = '${NODE_TYPE}';"
    ;;
  templates)
    # Search workflow templates
    if [ -z "$QUERY" ]; then
      echo "Usage: mcp.sh templates <query>"
      echo "Example: mcp.sh templates webhook slack notification"
      exit 1
    fi
    sqlite3 -header -column "$DB_FILE" \
      "SELECT id, name, SUBSTR(description, 1, 100) AS description
       FROM templates
       WHERE id IN (
         SELECT id FROM templates_fts WHERE templates_fts MATCH '${QUERY}'
       )
       LIMIT 20;"
    ;;
  template-nodes)
    # Get the node types used in a specific template
    if [ -z "$QUERY" ]; then
      echo "Usage: mcp.sh template-nodes <template_id>"
      exit 1
    fi
    sqlite3 -header -column "$DB_FILE" \
      "SELECT id, name, nodes_used FROM templates WHERE id = ${QUERY};"
    ;;
  categories)
    # List all node categories with counts
    sqlite3 -header -column "$DB_FILE" \
      "SELECT category, COUNT(*) AS count
       FROM nodes
       GROUP BY category
       ORDER BY count DESC;"
    ;;
  stats)
    # Database statistics
    echo "=== n8n-mcp Database Statistics ==="
    echo ""
    echo "Nodes:"
    sqlite3 "$DB_FILE" "SELECT COUNT(*) || ' total nodes' FROM nodes;"
    sqlite3 "$DB_FILE" "SELECT COUNT(*) || ' with documentation' FROM nodes WHERE documentation IS NOT NULL AND documentation != '';"
    sqlite3 "$DB_FILE" "SELECT COUNT(*) || ' with AI summaries' FROM nodes WHERE ai_documentation_summary IS NOT NULL AND ai_documentation_summary != '';"
    echo ""
    echo "Templates:"
    sqlite3 "$DB_FILE" "SELECT COUNT(*) || ' total templates' FROM templates;"
    echo ""
    echo "Categories:"
    sqlite3 -header -column "$DB_FILE" \
      "SELECT category, COUNT(*) AS count FROM nodes GROUP BY category ORDER BY count DESC LIMIT 10;"
    ;;
  sql)
    # Raw SQL for advanced queries
    if [ -z "$QUERY" ]; then
      echo "Usage: mcp.sh sql '<SQL query>'"
      echo "Example: mcp.sh sql 'SELECT node_type FROM nodes WHERE category = \"Action\"'"
      exit 1
    fi
    sqlite3 -header -column "$DB_FILE" "$QUERY"
    ;;
  *)
    echo "n8n Node Documentation — SQLite Query Interface"
    echo ""
    echo "Usage: .claude/scripts/mcp.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  search <query>          Search nodes by keyword (FTS5)"
    echo "  get <node_type>         Full node documentation"
    echo "  props <node_type>       Node properties/parameters (JSON)"
    echo "  ops <node_type>         Node operations (JSON)"
    echo "  templates <query>       Search workflow templates"
    echo "  template-nodes <id>     Get template node list"
    echo "  categories              List all node categories"
    echo "  stats                   Database statistics"
    echo "  sql '<query>'           Raw SQL (advanced)"
    echo ""
    echo "Examples:"
    echo "  mcp.sh search webhook"
    echo "  mcp.sh get n8n-nodes-base.webhook"
    echo "  mcp.sh props n8n-nodes-base.httpRequest"
    echo "  mcp.sh templates 'slack notification'"
    echo "  mcp.sh stats"
    exit 1
    ;;
esac
