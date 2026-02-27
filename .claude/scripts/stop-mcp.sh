#!/bin/bash
# Stop the background n8n-mcp HTTP server
if [ -f /tmp/n8n-mcp.pid ]; then
  kill $(cat /tmp/n8n-mcp.pid) 2>/dev/null
  rm /tmp/n8n-mcp.pid
  echo "✅ n8n-mcp server stopped"
else
  echo "No n8n-mcp server running"
fi
