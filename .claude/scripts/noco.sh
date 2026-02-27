#!/bin/bash
# NocoDB REST API wrapper — safe interface that reads tokens from .env
# Usage:
#   .claude/scripts/noco.sh list-bases
#   .claude/scripts/noco.sh list-tables
#   .claude/scripts/noco.sh list-records <tableId> [where] [limit] [offset]
#   .claude/scripts/noco.sh get-record <tableId> <recordId>
#   .claude/scripts/noco.sh create-record <tableId> '<json_data>'
#   .claude/scripts/noco.sh update-record <tableId> <recordId> '<json_data>'
#   .claude/scripts/noco.sh delete-record <tableId> <recordId>
if [ -f .env ]; then
  export $(grep -E '^NOCODB_' .env | xargs)
fi
if [ -z "$NOCODB_URL" ] || [ -z "$NOCODB_API_TOKEN" ]; then
  echo "❌ NOCODB_URL and NOCODB_API_TOKEN must be set. Run setup-env.sh first."
  exit 1
fi
BASE_URL="${NOCODB_URL}/api/v3"
AUTH_HEADER="Authorization: Bearer ${NOCODB_API_TOKEN}"
ACTION="$1"
case "$ACTION" in
  list-bases)
    curl -s -H "$AUTH_HEADER" "$BASE_URL/meta/bases"
    ;;
  list-tables)
    if [ -z "$NOCODB_BASE_ID" ]; then
      echo "❌ NOCODB_BASE_ID not set"
      exit 1
    fi
    curl -s -H "$AUTH_HEADER" "$BASE_URL/meta/bases/$NOCODB_BASE_ID/tables"
    ;;
  list-records)
    TABLE_ID="$2"
    WHERE="$3"
    LIMIT="${4:-25}"
    OFFSET="${5:-0}"
    QUERY="?limit=$LIMIT&offset=$OFFSET"
    [ -n "$WHERE" ] && QUERY="$QUERY&where=$WHERE"
    curl -s -H "$AUTH_HEADER" "$BASE_URL/$NOCODB_BASE_ID/$TABLE_ID$QUERY"
    ;;
  get-record)
    curl -s -H "$AUTH_HEADER" "$BASE_URL/$NOCODB_BASE_ID/$2/$3"
    ;;
  create-record)
    curl -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
      -d "$3" "$BASE_URL/$NOCODB_BASE_ID/$2"
    ;;
  update-record)
    curl -s -X PATCH -H "$AUTH_HEADER" -H "Content-Type: application/json" \
      -d "$4" "$BASE_URL/$NOCODB_BASE_ID/$2/$3"
    ;;
  delete-record)
    curl -s -X DELETE -H "$AUTH_HEADER" "$BASE_URL/$NOCODB_BASE_ID/$2/$3"
    ;;
  *)
    echo "Usage: noco.sh <action> [args...]"
    echo "Actions: list-bases, list-tables, list-records, get-record,"
    echo "         create-record, update-record, delete-record"
    exit 1
    ;;
esac
