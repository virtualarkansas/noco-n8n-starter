#!/bin/bash
# Start n8n-mcp as a local HTTP server for node documentation queries
# Provides: search_nodes, get_node, validate_node, search_templates,
#           get_template, validate_workflow, tools_documentation
# If n8n API is configured, also provides workflow management tools.
# Source n8n API config if available (enables management tools)
if [ -f .env ]; then
  export $(grep -E '^(N8N_URL|N8N_API_KEY)' .env | xargs)
  export N8N_API_URL="${N8N_URL}"
fi
export MCP_MODE=http
export PORT=3001
export LOG_LEVEL=error
export DISABLE_CONSOLE_OUTPUT=true
export N8N_MCP_TELEMETRY_DISABLED=true
# Kill any existing instance
if [ -f /tmp/n8n-mcp.pid ]; then
  kill $(cat /tmp/n8n-mcp.pid) 2>/dev/null
  rm /tmp/n8n-mcp.pid
fi
echo "Starting n8n-mcp HTTP server on port $PORT..."
npx -y n8n-mcp &
echo $! > /tmp/n8n-mcp.pid
# Wait for server to be ready
for i in {1..60}; do
  if curl -s http://localhost:$PORT/health > /dev/null 2>&1; then
    echo "✅ n8n-mcp server ready at http://localhost:$PORT"
    echo "   Node database: 1,084 nodes, 2,646 template configs"
    if [ -n "$N8N_API_URL" ]; then
      echo "   n8n management tools: enabled ($N8N_API_URL)"
    else
      echo "   n8n management tools: disabled (no N8N_URL configured)"
    fi
    exit 0
  fi
  sleep 1
done
echo "❌ n8n-mcp server failed to start within 60 seconds"
echo "   This may be a network issue in the Claude Code Web container."
echo "   Fallback: Use the hosted service at https://dashboard.n8n-mcp.com"
exit 1
