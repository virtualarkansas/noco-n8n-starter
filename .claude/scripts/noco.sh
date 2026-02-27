#!/bin/bash
# NocoDB REST API wrapper — safe interface that reads tokens from .env
#
# IMPORTANT: NocoDB uses two API versions:
#   v3 — data operations (records)
#   v2 — schema operations (tables, columns)
# This script handles the version routing automatically.
#
# Data commands (v3):
#   noco.sh list-bases
#   noco.sh list-tables
#   noco.sh list-records <tableId> [where] [limit] [offset]
#   noco.sh get-record <tableId> <recordId>
#   noco.sh create-record <tableId> '<json_data>'
#   noco.sh update-record <tableId> <recordId> '<json_data>'
#   noco.sh delete-record <tableId> <recordId>
#
# Schema commands (v2):
#   noco.sh create-table '<{"title":"MyTable"}'
#   noco.sh get-table <tableId>
#   noco.sh create-column <tableId> '<{"column_name":"Name","uidt":"SingleLineText"}'
if [ -f .env ]; then
  export $(grep -E '^NOCODB_' .env | xargs)
fi
if [ -z "$NOCODB_URL" ] || [ -z "$NOCODB_API_TOKEN" ]; then
  echo "❌ NOCODB_URL and NOCODB_API_TOKEN must be set. Run setup-env.sh first."
  exit 1
fi
# v3 for data (records), v2 for schema (tables/columns)
V3_URL="${NOCODB_URL}/api/v3"
V2_URL="${NOCODB_URL}/api/v2"
AUTH_HEADER="Authorization: Bearer ${NOCODB_API_TOKEN}"
ACTION="$1"
case "$ACTION" in
  # --- Data operations (v3 API) ---
  list-bases)
    curl -s -H "$AUTH_HEADER" "$V3_URL/meta/bases"
    ;;
  list-tables)
    if [ -z "$NOCODB_BASE_ID" ]; then
      echo "❌ NOCODB_BASE_ID not set"
      exit 1
    fi
    curl -s -H "$AUTH_HEADER" "$V3_URL/meta/bases/$NOCODB_BASE_ID/tables"
    ;;
  list-records)
    TABLE_ID="$2"
    WHERE="$3"
    LIMIT="${4:-25}"
    OFFSET="${5:-0}"
    QUERY="?limit=$LIMIT&offset=$OFFSET"
    [ -n "$WHERE" ] && QUERY="$QUERY&where=$WHERE"
    curl -s -H "$AUTH_HEADER" "$V3_URL/$NOCODB_BASE_ID/$TABLE_ID$QUERY"
    ;;
  get-record)
    curl -s -H "$AUTH_HEADER" "$V3_URL/$NOCODB_BASE_ID/$2/$3"
    ;;
  create-record)
    curl -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
      -d "$3" "$V3_URL/$NOCODB_BASE_ID/$2"
    ;;
  update-record)
    curl -s -X PATCH -H "$AUTH_HEADER" -H "Content-Type: application/json" \
      -d "$4" "$V3_URL/$NOCODB_BASE_ID/$2/$3"
    ;;
  delete-record)
    curl -s -X DELETE -H "$AUTH_HEADER" "$V3_URL/$NOCODB_BASE_ID/$2/$3"
    ;;

  # --- Schema operations (v2 API) ---
  # IMPORTANT: v3 silently ignores column definitions on table creation
  # and returns 404 for column endpoints. Always use v2 for schema.
  create-table)
    # Creates a table. Pass JSON with at least {"title":"TableName"}.
    # Do NOT include columns — add them separately with create-column.
    if [ -z "$NOCODB_BASE_ID" ]; then
      echo "❌ NOCODB_BASE_ID not set"
      exit 1
    fi
    curl -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
      -d "$2" "$V2_URL/meta/bases/$NOCODB_BASE_ID/tables"
    ;;
  get-table)
    # Returns table metadata including all column definitions.
    curl -s -H "$AUTH_HEADER" "$V2_URL/meta/tables/$2"
    ;;
  create-column)
    # Creates a single column on a table.
    # Example JSON: {"column_name":"Status","uidt":"SingleLineText"}
    # Common uidt values: SingleLineText, LongText, Number, Checkbox,
    #   SingleSelect, MultiSelect, Date, DateTime, Email, URL, Attachment
    # For SingleSelect, add dtxp for options: {"column_name":"Status",
    #   "uidt":"SingleSelect","dtxp":"'Todo','In Progress','Done'"}
    curl -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
      -d "$3" "$V2_URL/meta/tables/$2/columns"
    ;;

  *)
    echo "Usage: noco.sh <action> [args...]"
    echo ""
    echo "Data commands (v3 API — records):"
    echo "  list-bases                                   List all bases"
    echo "  list-tables                                  List tables in base"
    echo "  list-records <tableId> [where] [limit] [off] List records"
    echo "  get-record <tableId> <recordId>              Get one record"
    echo "  create-record <tableId> '<json>'             Create record(s)"
    echo "  update-record <tableId> <recordId> '<json>'  Update a record"
    echo "  delete-record <tableId> <recordId>           Delete a record"
    echo ""
    echo "Schema commands (v2 API — tables & columns):"
    echo "  create-table '<json>'                        Create a table"
    echo "  get-table <tableId>                          Get table metadata"
    echo "  create-column <tableId> '<json>'             Add a column"
    exit 1
    ;;
esac
