#!/bin/bash
# Usage: .claude/scripts/setup-env.sh <NOCODB_URL> <NOCODB_API_TOKEN> <NOCODB_BASE_ID> <N8N_URL> <N8N_API_KEY>
# All arguments are optional — only writes what's provided
ENV_FILE=".env"
# Clear existing
> "$ENV_FILE"
[ -n "$1" ] && echo "NOCODB_URL=$1" >> "$ENV_FILE"
[ -n "$2" ] && echo "NOCODB_API_TOKEN=$2" >> "$ENV_FILE"
[ -n "$3" ] && echo "NOCODB_BASE_ID=$3" >> "$ENV_FILE"
[ -n "$4" ] && echo "N8N_URL=$4" >> "$ENV_FILE"
[ -n "$5" ] && echo "N8N_API_KEY=$5" >> "$ENV_FILE"
echo "✅ Environment configured. Keys written to .env (gitignored)."
echo "Configured services:"
[ -n "$1" ] && echo "  • NocoDB: $1"
[ -n "$4" ] && echo "  • n8n: $4"
