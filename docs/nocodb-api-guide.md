# NocoDB REST API v3 — Complete Guide

This guide covers everything you need to interact with NocoDB's REST API.
All examples use the wrapper script (`bash .claude/scripts/noco.sh`) or
curl for reference.

---

## Table of Contents

1. [Authentication](#authentication)
2. [Base & Table Discovery](#base--table-discovery)
3. [CRUD Operations](#crud-operations)
4. [Filtering](#filtering)
5. [Sorting](#sorting)
6. [Pagination](#pagination)
7. [Field Selection](#field-selection)
8. [Linked Records](#linked-records)
9. [Error Handling](#error-handling)
10. [Official Documentation](#official-documentation)

---

## Authentication

NocoDB supports two authentication methods:

### Method 1: Bearer Token (Recommended)

```bash
# Header format:
Authorization: Bearer <your-api-token>

# Example curl:
curl -s \
  -H "Authorization: Bearer YOUR_TOKEN" \
  "https://app.nocodb.com/api/v3/meta/bases"
```

### Method 2: xc-token

```bash
# Header format:
xc-token: <your-api-token>

# Example curl:
curl -s \
  -H "xc-token: YOUR_TOKEN" \
  "https://app.nocodb.com/api/v3/meta/bases"
```

### Getting Your API Token

1. Open your NocoDB instance
2. Go to **Team & Settings** (bottom-left gear icon)
3. Click **API Tokens**
4. Click **Add New Token**, give it a name
5. Copy the token — you won't see it again!

### Using the Wrapper Script

The wrapper script handles authentication automatically by reading your
`.env` file. You never need to include tokens in commands:

```bash
# The wrapper script reads NOCODB_URL and NOCODB_API_TOKEN from .env
bash .claude/scripts/noco.sh list-bases
```

---

## Base & Table Discovery

Before you can read or write data, you need to know your Base ID and
Table IDs.

### List All Bases

```bash
# Using wrapper script:
bash .claude/scripts/noco.sh list-bases

# Equivalent curl:
curl -s \
  -H "Authorization: Bearer $TOKEN" \
  "$NOCODB_URL/api/v3/meta/bases"
```

**Response:**
```json
{
  "list": [
    {
      "id": "p_abc123",
      "title": "My Project",
      "description": "",
      "created_at": "2024-01-15T10:30:00.000Z"
    }
  ]
}
```

The `id` field (e.g., `p_abc123`) is your **Base ID**. It always starts
with `p`.

### List Tables in a Base

```bash
# Using wrapper script (reads NOCODB_BASE_ID from .env):
bash .claude/scripts/noco.sh list-tables

# Equivalent curl:
curl -s \
  -H "Authorization: Bearer $TOKEN" \
  "$NOCODB_URL/api/v3/meta/bases/$BASE_ID/tables"
```

**Response:**
```json
{
  "list": [
    {
      "id": "tbl_xyz789",
      "title": "Tasks",
      "columns": [
        { "id": "fld_name", "title": "Name", "uidt": "SingleLineText" },
        { "id": "fld_status", "title": "Status", "uidt": "SingleSelect" },
        { "id": "fld_due", "title": "Due Date", "uidt": "Date" }
      ]
    }
  ]
}
```

The `id` field (e.g., `tbl_xyz789`) is your **Table ID**.

---

## CRUD Operations

### Create a Record

```bash
# Using wrapper script:
bash .claude/scripts/noco.sh create-record tbl_xyz789 \
  '{"Name": "Buy groceries", "Status": "Todo", "Priority": 3}'

# Equivalent curl:
curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"Name": "Buy groceries", "Status": "Todo", "Priority": 3}' \
  "$NOCODB_URL/api/v3/$BASE_ID/tbl_xyz789"
```

**Response:**
```json
{
  "Id": 1,
  "Name": "Buy groceries",
  "Status": "Todo",
  "Priority": 3,
  "CreatedAt": "2024-01-15T12:00:00.000Z"
}
```

### Create Multiple Records

Send an array instead of a single object:

```bash
curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '[
    {"Name": "Task 1", "Status": "Todo"},
    {"Name": "Task 2", "Status": "Todo"},
    {"Name": "Task 3", "Status": "Done"}
  ]' \
  "$NOCODB_URL/api/v3/$BASE_ID/tbl_xyz789"
```

### Read Records (List)

```bash
# Using wrapper script:
bash .claude/scripts/noco.sh list-records tbl_xyz789

# With filtering:
bash .claude/scripts/noco.sh list-records tbl_xyz789 "(Status,eq,Todo)" 25 0

# Equivalent curl:
curl -s \
  -H "Authorization: Bearer $TOKEN" \
  "$NOCODB_URL/api/v3/$BASE_ID/tbl_xyz789?limit=25&offset=0"
```

**Response:**
```json
{
  "list": [
    { "Id": 1, "Name": "Buy groceries", "Status": "Todo", "Priority": 3 },
    { "Id": 2, "Name": "Walk the dog", "Status": "Done", "Priority": 1 }
  ],
  "pageInfo": {
    "totalRows": 42,
    "page": 1,
    "pageSize": 25,
    "isFirstPage": true,
    "isLastPage": false
  }
}
```

### Read a Single Record

```bash
# Using wrapper script:
bash .claude/scripts/noco.sh get-record tbl_xyz789 1

# Equivalent curl:
curl -s \
  -H "Authorization: Bearer $TOKEN" \
  "$NOCODB_URL/api/v3/$BASE_ID/tbl_xyz789/1"
```

### Update a Record

```bash
# Using wrapper script:
bash .claude/scripts/noco.sh update-record tbl_xyz789 1 \
  '{"Status": "Done", "Priority": 1}'

# Equivalent curl:
curl -s -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"Status": "Done", "Priority": 1}' \
  "$NOCODB_URL/api/v3/$BASE_ID/tbl_xyz789/1"
```

**Note:** PATCH only updates the fields you include. Other fields remain
unchanged.

### Delete a Record

```bash
# Using wrapper script:
bash .claude/scripts/noco.sh delete-record tbl_xyz789 1

# Equivalent curl:
curl -s -X DELETE \
  -H "Authorization: Bearer $TOKEN" \
  "$NOCODB_URL/api/v3/$BASE_ID/tbl_xyz789/1"
```

---

## Filtering

Use the `where` query parameter to filter records. This is one of the
most powerful features of the NocoDB API.

### Basic Syntax

```
?where=(FieldName,operator,value)
```

### Available Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `eq` | Equals | `(Status,eq,Active)` |
| `neq` | Not equals | `(Status,neq,Archived)` |
| `gt` | Greater than | `(Priority,gt,3)` |
| `gte` | Greater than or equal | `(Priority,gte,3)` |
| `lt` | Less than | `(Priority,lt,5)` |
| `lte` | Less than or equal | `(Priority,lte,5)` |
| `like` | Contains (text) | `(Name,like,grocery)` |
| `nlike` | Does not contain | `(Name,nlike,test)` |
| `is` | Is null/empty | `(Email,is,null)` |
| `isnot` | Is not null/empty | `(Email,isnot,null)` |

### Combining Filters

Use `~and` or `~or` to combine multiple conditions:

```bash
# Records where Status=Active AND Priority >= 3
?where=(Status,eq,Active)~and(Priority,gte,3)

# Records where Status=Todo OR Status=InProgress
?where=(Status,eq,Todo)~or(Status,eq,InProgress)

# Complex: Active with high priority OR flagged
?where=(Status,eq,Active)~and(Priority,gte,4)~or(Flagged,eq,true)
```

### Curl Examples

```bash
# All active records:
curl -s -H "Authorization: Bearer $TOKEN" \
  "$NOCODB_URL/api/v3/$BASE_ID/$TABLE_ID?where=(Status,eq,Active)"

# High-priority active records:
curl -s -H "Authorization: Bearer $TOKEN" \
  "$NOCODB_URL/api/v3/$BASE_ID/$TABLE_ID?where=(Status,eq,Active)~and(Priority,gte,3)"

# Search by name (contains "report"):
curl -s -H "Authorization: Bearer $TOKEN" \
  "$NOCODB_URL/api/v3/$BASE_ID/$TABLE_ID?where=(Name,like,report)"
```

### Using Filters with the Wrapper Script

```bash
# The third argument to list-records is the where clause:
bash .claude/scripts/noco.sh list-records tbl_xyz789 "(Status,eq,Active)"

# With limit and offset:
bash .claude/scripts/noco.sh list-records tbl_xyz789 "(Status,eq,Active)" 10 0
```

---

## Sorting

Use the `sort` query parameter to order results.

### Syntax

```bash
# Sort by one field (ascending):
?sort=FieldName

# Sort descending (prefix with -):
?sort=-FieldName

# Sort by multiple fields (comma-separated):
?sort=Status,-Priority,Name
```

### Examples

```bash
# Newest first:
curl -s -H "Authorization: Bearer $TOKEN" \
  "$NOCODB_URL/api/v3/$BASE_ID/$TABLE_ID?sort=-CreatedAt"

# By status (A-Z), then by priority (highest first):
curl -s -H "Authorization: Bearer $TOKEN" \
  "$NOCODB_URL/api/v3/$BASE_ID/$TABLE_ID?sort=Status,-Priority"
```

---

## Pagination

NocoDB returns paginated results. Use `limit` and `offset` to navigate.

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `limit` | 25 | Number of records per page (max varies by plan) |
| `offset` | 0 | Number of records to skip |

### Examples

```bash
# First 10 records:
?limit=10&offset=0

# Records 11-20:
?limit=10&offset=10

# Records 21-30:
?limit=10&offset=20
```

### Checking Pagination Info

The response includes a `pageInfo` object:

```json
{
  "list": [...],
  "pageInfo": {
    "totalRows": 150,
    "page": 1,
    "pageSize": 25,
    "isFirstPage": true,
    "isLastPage": false
  }
}
```

Use `totalRows` to calculate total pages: `Math.ceil(totalRows / limit)`.

### Paginating Through All Records

```bash
# Page 1:
bash .claude/scripts/noco.sh list-records tbl_xyz789 "" 25 0
# Page 2:
bash .claude/scripts/noco.sh list-records tbl_xyz789 "" 25 25
# Page 3:
bash .claude/scripts/noco.sh list-records tbl_xyz789 "" 25 50
```

---

## Field Selection

Reduce response size by requesting only the fields you need.

### Syntax

```bash
?fields=Field1,Field2,Field3
```

### Examples

```bash
# Only get Name and Email:
curl -s -H "Authorization: Bearer $TOKEN" \
  "$NOCODB_URL/api/v3/$BASE_ID/$TABLE_ID?fields=Name,Email"

# Combine with filtering and sorting:
curl -s -H "Authorization: Bearer $TOKEN" \
  "$NOCODB_URL/api/v3/$BASE_ID/$TABLE_ID?fields=Name,Status,Priority&where=(Status,eq,Active)&sort=-Priority"
```

---

## Linked Records

NocoDB supports linked records (relations between tables), similar to
foreign keys in a traditional database.

### How Links Work

When you create a Link field in NocoDB, it creates a relationship between
two tables. The API represents linked records as nested objects.

### Reading Linked Records

Linked fields appear in the record response as nested objects or arrays:

```json
{
  "Id": 1,
  "Name": "Alice",
  "Department": {
    "Id": 3,
    "Title": "Engineering"
  },
  "Tasks": [
    { "Id": 10, "Title": "Review PR" },
    { "Id": 11, "Title": "Deploy v2" }
  ]
}
```

- **Belongs-to / Has-one** links return a single object
- **Has-many / Many-to-many** links return an array

### Creating Records with Links

Reference linked records by their row ID:

```bash
curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"Name": "New Task", "Assignee": 1}' \
  "$NOCODB_URL/api/v3/$BASE_ID/$TABLE_ID"
```

---

## Error Handling

### Common Status Codes

| Code | Meaning | What to Do |
|------|---------|------------|
| `200` | Success | Request completed normally |
| `201` | Created | Record was created successfully |
| `400` | Bad Request | Check your JSON syntax or field names |
| `401` | Unauthorized | Your API token is invalid or expired |
| `403` | Forbidden | Token doesn't have permission for this action |
| `404` | Not Found | Check your base ID, table ID, or record ID |
| `422` | Validation Error | Data doesn't match field type (e.g., text in number field) |
| `429` | Rate Limited | Too many requests — wait 30 seconds and retry |

### Rate Limiting

NocoDB enforces a rate limit of **5 requests per second per user**.

If you get a `429` response:
1. Wait 30 seconds before retrying
2. Consider batching operations (create multiple records in one call)
3. Add delays between sequential API calls in workflows

### Debugging Tips

1. **401 errors:** Regenerate your API token and update `.env`
2. **404 errors:** Use `list-bases` and `list-tables` to verify IDs
3. **400 errors:** Check that field names match exactly (case-sensitive)
4. **Empty results:** Verify your `where` clause syntax — a malformed
   filter silently returns no results

---

## Official Documentation

- **Data APIs (v2):** https://data-apis-v2.nocodb.com/
- **All APIs:** https://all-apis.nocodb.com/
- **NocoDB Docs:** https://docs.nocodb.com/
- **Self-hosting:** https://docs.nocodb.com/getting-started/self-hosted/installation
