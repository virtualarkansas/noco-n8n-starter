# NocoFlow Starter — Project Context for Claude Code

## What This Project Is

A development environment for building:
1. **NocoDB dashboards** — web interfaces backed by NocoDB as the database
2. **n8n workflows** — automation workflows connecting services, APIs, and NocoDB
3. **Frontend interfaces** — HTML/CSS/JS pages served via n8n webhook nodes
4. **Custom n8n nodes** — TypeScript nodes for extending n8n (optional)

Target audience: beginner developers. Prioritize clarity, comments, and
step-by-step guidance in all code and explanations.

---

## ⚠️ SECURITY RULES — ALWAYS FOLLOW

1. NEVER echo, print, cat, or display the value of any API key or token
2. NEVER commit .env files or their contents to git
3. NEVER include API keys in curl commands — use the wrapper scripts instead
4. When debugging auth errors: check if a key IS SET ([ -z "$VAR" ]), never show it
5. NEVER put API tokens in workflow JSON files — use n8n credentials system
6. If a script fails with 401/403, tell the user to re-check their token — don't try to read it

---

## Session Bootstrap

This project uses a SessionStart hook (.claude/settings.json) that
automatically runs scripts/install_pkgs.sh when you open the repo.
It handles:

- Downloading n8n node database (data/nodes.db — all 1,084 nodes via SQLite)
- Downloading n8n-skills (7 workflow pattern guides → .claude/skills/)
- Making all scripts executable

Check the bootstrap output above for current status. If anything failed,
re-run manually: `bash scripts/install_pkgs.sh`

The only manual step each session is providing API keys (if needed):
```bash
bash .claude/scripts/setup-env.sh <NOCODB_URL> <TOKEN> <BASE_ID> <N8N_URL> <KEY>
```

---

## Architecture Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Frontend HTML   │────▶│  n8n Webhooks    │────▶│    NocoDB       │
│ (served by n8n)  │◀────│  (workflows)     │◀────│   (database)    │
└─────────────────┘     └──────────────────┘     └─────────────────┘
        │                        │
        │  fetch() / POST        │  HTTP Request node
        ▼                        ▼
   Browser User           External APIs
```

**Data flow:**
- n8n Webhook node receives HTTP GET → serves HTML from frontend/templates/
- Frontend JavaScript calls n8n webhook endpoints via fetch()
- n8n workflows read/write NocoDB via HTTP Request node
- NocoDB stores all structured data (tables, views, forms)

---

## Available Tools

### n8n Node Database (data/nodes.db)

A pre-built SQLite database containing all 1,084 n8n node docs, property
schemas, operations, and 2,646+ workflow template configurations. Downloaded
automatically by the SessionStart hook. No server needed — queries run
directly via sqlite3.

**Query it:** `bash .claude/scripts/mcp.sh <command> [args]`

**Key commands for building workflows:**

```bash
# Search for nodes by keyword
bash .claude/scripts/mcp.sh search webhook
bash .claude/scripts/mcp.sh search "slack notification"

# Get full documentation for a specific node
bash .claude/scripts/mcp.sh get n8n-nodes-base.webhook

# Get node properties/parameter schema (JSON)
bash .claude/scripts/mcp.sh props n8n-nodes-base.httpRequest

# Get node operations
bash .claude/scripts/mcp.sh ops n8n-nodes-base.httpRequest

# Search workflow templates
bash .claude/scripts/mcp.sh templates "webhook notification"

# View database statistics
bash .claude/scripts/mcp.sh stats

# Run custom SQL for advanced queries
bash .claude/scripts/mcp.sh sql "SELECT node_type, display_name FROM nodes WHERE category = 'Action' LIMIT 10"
```

**WORKFLOW BUILDING PROCESS:**
1. ALWAYS search templates first — there are 2,646+ available
2. Use `mcp.sh get` and `mcp.sh props` for every node you configure
3. NEVER guess parameter names — look them up in the properties JSON
4. Check operations with `mcp.sh ops` before configuring a node
5. Reference template examples with `mcp.sh templates` for patterns

### n8n-skills (in .claude/skills/)

7 specialized skills for n8n development are loaded from .claude/skills/.
These teach correct expression syntax, workflow patterns, validation,
and code node usage. They activate automatically when relevant.

### NocoDB API (via wrapper script)

```bash
bash .claude/scripts/noco.sh list-bases
bash .claude/scripts/noco.sh list-tables
bash .claude/scripts/noco.sh list-records <tableId> [where] [limit] [offset]
bash .claude/scripts/noco.sh get-record <tableId> <recordId>
bash .claude/scripts/noco.sh create-record <tableId> '<json>'
bash .claude/scripts/noco.sh update-record <tableId> <recordId> '<json>'
bash .claude/scripts/noco.sh delete-record <tableId> <recordId>
```

### n8n API (via wrapper script)

```bash
bash .claude/scripts/n8n.sh list-workflows
bash .claude/scripts/n8n.sh get-workflow <id>
bash .claude/scripts/n8n.sh create-workflow '<workflow_json>'
bash .claude/scripts/n8n.sh update-workflow <id> '<workflow_json>'
bash .claude/scripts/n8n.sh activate <id>
bash .claude/scripts/n8n.sh deactivate <id>
bash .claude/scripts/n8n.sh list-executions [workflowId]
```

---

## Environment Variables

Provide these at session start via:
```bash
bash .claude/scripts/setup-env.sh <NOCODB_URL> <NOCODB_TOKEN> <NOCODB_BASE_ID> <N8N_URL> <N8N_API_KEY>
```

### NocoDB
- NOCODB_URL — Instance URL (e.g., https://app.nocodb.com or http://localhost:8080)
- NOCODB_API_TOKEN — API token (Team & Settings → API Tokens)
- NOCODB_BASE_ID — Base ID (alphanumeric, prefixed with 'p', visible in URL)

### n8n
- N8N_URL — Instance URL (e.g., https://your-name.app.n8n.cloud or http://localhost:5678)
- N8N_API_KEY — API key (Settings → n8n API → Create an API key)

All are optional. The template works without them.

---

## API Quick References

### NocoDB REST API (v3)

**Base URL:** {NOCODB_URL}/api/v3
**Auth:** Authorization: Bearer {token} or xc-token: {token}
**Rate limit:** 5 req/sec/user (429 = wait 30s)

**Key endpoints:**
- GET /meta/bases — list all bases
- GET /meta/bases/{baseId}/tables — list tables in a base
- GET /{baseId}/{tableId} — list records (supports where, sort, fields, limit, offset)
- POST /{baseId}/{tableId} — create record(s)
- PATCH /{baseId}/{tableId}/{recordId} — update a record
- DELETE /{baseId}/{tableId}/{recordId} — delete a record

**Filtering:** ?where=(Status,eq,Active)~and(Priority,gte,3)
**Operators:** eq, neq, gt, gte, lt, lte, like, nlike, is, isnot

**Docs:** https://data-apis-v2.nocodb.com/ and https://all-apis.nocodb.com/

### n8n REST API

**Base URL:** {N8N_URL}/api/v1
**Auth:** X-N8N-API-KEY: {key}

**Key endpoints:**
- GET /workflows — list workflows
- POST /workflows — create workflow
- GET /workflows/{id} — get workflow details
- PUT /workflows/{id} — update workflow
- POST /workflows/{id}/activate — activate
- GET /executions — list execution history

**Docs:** https://docs.n8n.io/api/

---

## Serving Frontend from n8n Webhooks

### Pattern: Webhook → Respond with HTML

1. **Webhook node**: HTTP Method = GET, Path = /dashboard
2. **Respond to Webhook node**: Response Mode = Text, Content-Type = text/html
3. Paste HTML into the Body field (or use expression to load it)

### Limitations (n8n >= v1.103.0):
- HTML responses are wrapped in a sandboxed iframe
- JavaScript cannot access window.top, localStorage, or sessionStorage
- Use **absolute URLs** for all links and form actions
- For auth, embed short-lived tokens in HTML (no cookie/header auth in iframe)
- Forms POST to separate webhook endpoints using fetch() with full URLs

### Frontend-to-n8n Communication:

```javascript
const N8N_BASE = 'https://your-n8n-instance.com/webhook';

async function loadRecords() {
  const response = await fetch(`${N8N_BASE}/api/records`);
  const data = await response.json();
  renderTable(data);
}

async function createRecord(formData) {
  await fetch(`${N8N_BASE}/api/records`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(formData)
  });
}
```

---

## Working with n8n Workflows

### Workflow JSON Structure

n8n workflows are JSON with nodes and connections arrays.

**CRITICAL:** Always use the n8n node database to:
- Look up correct node types (e.g., n8n-nodes-base.webhook, not webhook)
- Get required properties for each node
- Check operations and parameter schemas before configuring

### Common Patterns:
1. **Dashboard server**: Webhook GET → Respond with HTML
2. **API proxy**: Webhook POST → NocoDB CRUD → Respond with JSON
3. **Form handler**: Webhook POST → Validate → NocoDB Insert → Respond
4. **Scheduled sync**: Schedule Trigger → HTTP Request → NocoDB Upsert

### Most-Used n8n Node Types:
- n8n-nodes-base.webhook — HTTP trigger
- n8n-nodes-base.respondToWebhook — Send HTTP response
- n8n-nodes-base.httpRequest — Make HTTP calls (to NocoDB, etc.)
- n8n-nodes-base.code — JavaScript/Python scripting
- n8n-nodes-base.set — Data transformation
- n8n-nodes-base.if — Conditional routing
- n8n-nodes-base.switch — Multi-branch routing
- n8n-nodes-base.merge — Combine data streams
- n8n-nodes-base.scheduleTrigger — Time-based triggers
- n8n-nodes-base.manualTrigger — Manual execution
- @n8n/n8n-nodes-langchain.agent — AI agents

---

## NocoDB as Dashboard (No-Code Option)

Users may choose to use NocoDB's built-in views as their dashboard instead
of building custom HTML. This is faster for internal tools and prototypes.

### Two Dashboard Approaches:

**1. NocoDB Native** — Use NocoDB views (grid, gallery, kanban, form, calendar)
as the UI. Add button columns to trigger n8n webhooks for row-level actions.
Configure record webhooks for automatic triggers (after insert/update/delete).
Share views via public links for read-only dashboards.

**2. Custom Frontend** — Build HTML/CSS/JS pages served via n8n webhooks.
Full design control but requires more development effort.
See docs/n8n-webhook-frontend.md for details.

### NocoDB Button Columns → n8n

Button columns let users trigger n8n workflows from within NocoDB:

1. Create a webhook in NocoDB (table settings → Webhooks)
   - Event: use "Manual Trigger" type for button-triggered webhooks
   - Method & URL: point to your n8n webhook endpoint
2. Add a Button column to the table
   - Action: "Run Webhook"
   - Select the webhook you created
3. n8n webhook receives the record data and performs the action
4. n8n can update the NocoDB record via API to reflect results

**Limitations:**
- Button columns don't work in shared views or shared bases
- Conditional webhooks only fire on condition state transitions (false → true)
- Custom webhook payloads require NocoDB Enterprise

### NocoDB Record Webhooks (Automatic)

Trigger n8n workflows automatically on record events:
- After Insert / After Update / After Delete
- After Bulk Insert / Bulk Update / Bulk Delete
- Optional conditions: only trigger when specific fields match criteria

Example n8n webhook URL: {N8N_URL}/webhook/nocodb-record-update

See docs/nocodb-dashboard-patterns.md for full guide.

---

## Custom n8n Node Development

Custom nodes live in n8n-nodes/:

```
n8n-nodes/
├── package.json          # Must follow naming: n8n-nodes-<name>
├── tsconfig.json
├── nodes/
│   └── MyNode/
│       ├── MyNode.node.ts       # Node logic (implements INodeType)
│       └── MyNode.node.json     # Node UI description
└── credentials/
    └── MyApi.credentials.ts     # Credential type definition
```

**Key requirements:**
- Package name must match pattern n8n-nodes-*
- Node class must implement INodeType
- Use this.getNodeParameter() for inputs
- Use this.helpers.httpRequest() for API calls
- Docs: https://docs.n8n.io/integrations/creating-nodes/

---

## Project Conventions

- Frontend HTML: self-contained or CDN links (for easy webhook serving)
- Vanilla JavaScript (no build step) — beginner-friendly
- Store workflow JSONs in workflows/examples/ with descriptive names
- Use .env for all secrets — never commit tokens
- Comment thoroughly — this is a learning template
- Prefer fetch() over XMLHttpRequest
- Use async/await over .then() chains
- All code should work in modern browsers (ES2020+)
