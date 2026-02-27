#!/bin/bash
# Query the local n8n-mcp HTTP server
# Usage:
#   .claude/scripts/mcp.sh search_nodes '{"query":"slack"}'
#   .claude/scripts/mcp.sh get_node '{"nodeType":"n8n-nodes-base.webhook","detail":"standard"}'
#   .claude/scripts/mcp.sh validate_node '{"nodeType":"...","config":{...},"mode":"full"}'
#   .claude/scripts/mcp.sh search_templates '{"query":"webhook notification"}'
#   .claude/scripts/mcp.sh get_template '{"templateId":1234}'
#   .claude/scripts/mcp.sh validate_workflow '{"workflow":{...}}'
#   .claude/scripts/mcp.sh tools_documentation '{}'
TOOL_NAME="$1"
ARGUMENTS="$2"
PORT="${N8N_MCP_PORT:-3001}"
if [ -z "$TOOL_NAME" ]; then
  echo "Usage: mcp.sh <tool_name> '<json_arguments>'"
  echo ""
  echo "Core tools: search_nodes, get_node, validate_node, search_templates,"
  echo "            get_template, validate_workflow, tools_documentation"
  echo ""
  echo "n8n tools (requires API key): n8n_list_workflows, n8n_create_workflow,"
  echo "  n8n_get_workflow, n8n_update_full_workflow, n8n_update_partial_workflow,"
  echo "  n8n_delete_workflow, n8n_validate_workflow, n8n_autofix_workflow,"
  echo "  n8n_test_workflow, n8n_executions, n8n_deploy_template, n8n_health_check"
  exit 1
fi
[ -z "$ARGUMENTS" ] && ARGUMENTS="{}"
RESPONSE=$(curl -s -X POST "http://localhost:$PORT/mcp" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"tools/call\",
    \"params\": {
      \"name\": \"$TOOL_NAME\",
      \"arguments\": $ARGUMENTS
    },
    \"id\": 1
  }")
echo "$RESPONSE"
