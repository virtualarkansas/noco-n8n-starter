# n8n REST API — Complete Guide

This guide covers the n8n REST API for managing workflows, monitoring
executions, and interacting with your n8n instance programmatically.

---

## Table of Contents

1. [Authentication](#authentication)
2. [Workflow CRUD](#workflow-crud)
3. [Activation & Deactivation](#activation--deactivation)
4. [Execution History](#execution-history)
5. [Importing & Exporting Workflows](#importing--exporting-workflows)
6. [Webhook URL Patterns](#webhook-url-patterns)
7. [Error Handling](#error-handling)
8. [Official Documentation](#official-documentation)

---

## Authentication

All n8n API requests require an API key sent in the `X-N8N-API-KEY` header.

### Getting Your API Key

1. Open your n8n instance
2. Go to **Settings** (gear icon in the left sidebar)
3. Click **n8n API**
4. Click **Create an API key**
5. Copy the key — store it safely!

### Header Format

```bash
X-N8N-API-KEY: your-api-key-here
```

### Example Request

```bash
curl -s \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  "$N8N_URL/api/v1/workflows"
```

### Using the Wrapper Script

The wrapper script handles authentication automatically:

```bash
# Reads N8N_URL and N8N_API_KEY from .env
bash .claude/scripts/n8n.sh list-workflows
```

---

## Workflow CRUD

### List All Workflows

```bash
# Using wrapper script:
bash .claude/scripts/n8n.sh list-workflows

# Equivalent curl:
curl -s \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  "$N8N_URL/api/v1/workflows"
```

**Response:**
```json
{
  "data": [
    {
      "id": "1001",
      "name": "My Dashboard",
      "active": true,
      "createdAt": "2024-01-15T10:30:00.000Z",
      "updatedAt": "2024-01-16T14:20:00.000Z",
      "tags": []
    }
  ]
}
```

### Get a Single Workflow

Returns the complete workflow including all nodes and connections:

```bash
# Using wrapper script:
bash .claude/scripts/n8n.sh get-workflow 1001

# Equivalent curl:
curl -s \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  "$N8N_URL/api/v1/workflows/1001"
```

**Response:**
```json
{
  "id": "1001",
  "name": "My Dashboard",
  "active": true,
  "nodes": [
    {
      "parameters": { "httpMethod": "GET", "path": "dashboard" },
      "type": "n8n-nodes-base.webhook",
      "name": "Webhook",
      "position": [250, 300]
    },
    {
      "parameters": {
        "respondWith": "text",
        "responseBody": "<html>...</html>",
        "options": { "responseHeaders": { "values": [
          { "name": "Content-Type", "value": "text/html" }
        ]}}
      },
      "type": "n8n-nodes-base.respondToWebhook",
      "name": "Respond to Webhook",
      "position": [450, 300]
    }
  ],
  "connections": {
    "Webhook": {
      "main": [[{ "node": "Respond to Webhook", "type": "main", "index": 0 }]]
    }
  }
}
```

### Create a Workflow

```bash
# Using wrapper script:
bash .claude/scripts/n8n.sh create-workflow '{
  "name": "New Dashboard",
  "nodes": [
    {
      "parameters": { "httpMethod": "GET", "path": "my-page" },
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 2,
      "name": "Webhook",
      "position": [250, 300]
    }
  ],
  "connections": {},
  "settings": { "executionOrder": "v1" }
}'

# Equivalent curl:
curl -s -X POST \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"New Dashboard","nodes":[...],"connections":{}}' \
  "$N8N_URL/api/v1/workflows"
```

**Response:** Returns the created workflow with its new `id`.

### Update a Workflow

**Important:** PUT replaces the entire workflow. Always GET the current
workflow first, modify it, then PUT the full object back.

```bash
# Using wrapper script:
bash .claude/scripts/n8n.sh update-workflow 1001 '{
  "name": "Updated Dashboard",
  "nodes": [...],
  "connections": {...},
  "settings": { "executionOrder": "v1" }
}'

# Equivalent curl:
curl -s -X PUT \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated Dashboard","nodes":[...],"connections":{...}}' \
  "$N8N_URL/api/v1/workflows/1001"
```

### Delete a Workflow

```bash
# curl (no wrapper script command for delete — safety measure):
curl -s -X DELETE \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  "$N8N_URL/api/v1/workflows/1001"
```

**Warning:** Deletion is permanent. There is no undo.

---

## Activation & Deactivation

Workflows must be activated before their triggers (webhooks, schedules)
start listening for events.

### Activate a Workflow

```bash
# Using wrapper script:
bash .claude/scripts/n8n.sh activate 1001

# Equivalent curl:
curl -s -X POST \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  "$N8N_URL/api/v1/workflows/1001/activate"
```

### Deactivate a Workflow

```bash
# Using wrapper script:
bash .claude/scripts/n8n.sh deactivate 1001

# Equivalent curl:
curl -s -X POST \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  "$N8N_URL/api/v1/workflows/1001/deactivate"
```

### Check Activation Status

```bash
# Get the workflow and check the "active" field:
bash .claude/scripts/n8n.sh get-workflow 1001
# Look for: "active": true or "active": false
```

**Important:** After creating or updating a workflow, you typically need
to activate it (or re-activate it) for changes to take effect on triggers.

---

## Execution History

Executions are records of workflow runs. Use them for debugging and
monitoring.

### List All Executions

```bash
# Using wrapper script:
bash .claude/scripts/n8n.sh list-executions

# Equivalent curl:
curl -s \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  "$N8N_URL/api/v1/executions"
```

**Response:**
```json
{
  "data": [
    {
      "id": "5001",
      "finished": true,
      "mode": "webhook",
      "startedAt": "2024-01-16T14:30:00.000Z",
      "stoppedAt": "2024-01-16T14:30:01.200Z",
      "workflowId": "1001",
      "status": "success"
    }
  ]
}
```

### List Executions for a Specific Workflow

```bash
# Using wrapper script:
bash .claude/scripts/n8n.sh list-executions 1001

# Equivalent curl:
curl -s \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  "$N8N_URL/api/v1/executions?workflowId=1001"
```

### Understanding Execution Status

| Status | Meaning |
|--------|---------|
| `success` | Workflow completed without errors |
| `error` | Workflow failed — check execution data for details |
| `waiting` | Workflow is paused, waiting for an event |
| `running` | Workflow is currently executing |

---

## Importing & Exporting Workflows

### Exporting a Workflow (Backup)

To export a workflow, GET it and save the JSON:

```bash
# Get the workflow JSON:
bash .claude/scripts/n8n.sh get-workflow 1001

# Save to a file (using curl directly):
curl -s \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  "$N8N_URL/api/v1/workflows/1001" > workflows/examples/my-dashboard.json
```

### Importing a Workflow (Restore)

To import a workflow, POST the JSON:

```bash
# From a saved file:
bash .claude/scripts/n8n.sh create-workflow "$(cat workflows/examples/my-dashboard.json)"
```

### Workflow JSON Structure

A workflow JSON has this structure:

```json
{
  "name": "Workflow Name",
  "nodes": [
    {
      "parameters": {},
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 2,
      "name": "Webhook",
      "position": [250, 300]
    }
  ],
  "connections": {
    "NodeName": {
      "main": [
        [
          { "node": "NextNodeName", "type": "main", "index": 0 }
        ]
      ]
    }
  },
  "settings": {
    "executionOrder": "v1"
  }
}
```

**Key fields:**
- `nodes` — Array of all nodes in the workflow
- `connections` — How nodes are wired together
- `settings` — Workflow-level configuration
- Each node has `type` (the node identifier), `parameters`, and `position`

---

## Webhook URL Patterns

When you create a Webhook node in n8n, it gets a URL that external
services (or your frontend) can call.

### URL Format

```
# Production (active workflow):
{N8N_URL}/webhook/{path}

# Test (workflow editor test mode):
{N8N_URL}/webhook-test/{path}
```

### Examples

If your n8n instance is at `https://my-n8n.app.n8n.cloud` and your
Webhook node's path is `dashboard`:

```
Production:  https://my-n8n.app.n8n.cloud/webhook/dashboard
Test mode:   https://my-n8n.app.n8n.cloud/webhook-test/dashboard
```

### Multiple Webhooks

A single workflow can have multiple Webhook nodes with different paths
and methods:

```
GET  /webhook/dashboard        → Serve HTML page
GET  /webhook/api/records      → Return JSON data
POST /webhook/api/records      → Create a record
POST /webhook/api/records/edit → Update a record
```

---

## Error Handling

### Common Status Codes

| Code | Meaning | What to Do |
|------|---------|------------|
| `200` | Success | Request completed |
| `401` | Unauthorized | Check your API key |
| `404` | Not Found | Verify the workflow/execution ID |
| `500` | Server Error | Check n8n logs for details |

### Common Issues

1. **"Unauthorized" (401):**
   - Verify your API key is correct
   - Check that the API is enabled in n8n settings
   - Ensure the key hasn't been revoked

2. **Workflow not triggering:**
   - Make sure the workflow is **activated**
   - Check the webhook path matches the URL you're calling
   - Verify the HTTP method matches (GET vs POST)

3. **Webhook returns empty response:**
   - Ensure you have a "Respond to Webhook" node connected
   - The Respond to Webhook node must be downstream of the Webhook node

4. **"Workflow could not be activated" error:**
   - Check for configuration errors in trigger nodes
   - Ensure all required credentials are set up

---

## Official Documentation

- **n8n API Reference:** https://docs.n8n.io/api/
- **n8n Docs Home:** https://docs.n8n.io/
- **Webhook Node:** https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/
- **n8n Community:** https://community.n8n.io/
