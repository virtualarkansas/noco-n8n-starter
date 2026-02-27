#!/bin/bash
# n8n REST API wrapper — safe interface that reads tokens from .env
# Usage:
#   .claude/scripts/n8n.sh health
#   .claude/scripts/n8n.sh list-workflows
#   .claude/scripts/n8n.sh get-workflow <id>
#   .claude/scripts/n8n.sh create-workflow '<json>'
#   .claude/scripts/n8n.sh update-workflow <id> '<json>'
#   .claude/scripts/n8n.sh activate <id>
#   .claude/scripts/n8n.sh deactivate <id>
#   .claude/scripts/n8n.sh list-executions [workflowId]
if [ -f .env ]; then
  export $(grep -E '^N8N_' .env | xargs)
fi
if [ -z "$N8N_URL" ] || [ -z "$N8N_API_KEY" ]; then
  echo "❌ N8N_URL and N8N_API_KEY must be set. Run setup-env.sh first."
  exit 1
fi
BASE_URL="${N8N_URL}/api/v1"
AUTH_HEADER="X-N8N-API-KEY: ${N8N_API_KEY}"
ACTION="$1"
case "$ACTION" in
  health)
    curl -s -H "$AUTH_HEADER" "$BASE_URL/workflows?limit=1" | head -c 200
    echo ""
    ;;
  list-workflows)
    curl -s -H "$AUTH_HEADER" "$BASE_URL/workflows"
    ;;
  get-workflow)
    curl -s -H "$AUTH_HEADER" "$BASE_URL/workflows/$2"
    ;;
  create-workflow)
    curl -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
      -d "$2" "$BASE_URL/workflows"
    ;;
  update-workflow)
    curl -s -X PUT -H "$AUTH_HEADER" -H "Content-Type: application/json" \
      -d "$3" "$BASE_URL/workflows/$2"
    ;;
  activate)
    curl -s -X POST -H "$AUTH_HEADER" "$BASE_URL/workflows/$2/activate"
    ;;
  deactivate)
    curl -s -X POST -H "$AUTH_HEADER" "$BASE_URL/workflows/$2/deactivate"
    ;;
  list-executions)
    QUERY=""
    [ -n "$2" ] && QUERY="?workflowId=$2"
    curl -s -H "$AUTH_HEADER" "$BASE_URL/executions$QUERY"
    ;;
  list-credentials)
    curl -s -H "$AUTH_HEADER" "$BASE_URL/credentials"
    ;;
  *)
    echo "Usage: n8n.sh <action> [args...]"
    echo "Actions: health, list-workflows, get-workflow, create-workflow,"
    echo "         update-workflow, activate, deactivate, list-executions,"
    echo "         list-credentials"
    exit 1
    ;;
esac
