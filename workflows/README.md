# Example Workflows

This directory contains ready-to-import n8n workflow JSON files that
demonstrate common patterns for building NocoDB-backed applications.

---

## What's Included

### 1. `serve-dashboard.json` — Serve HTML Page

The simplest possible pattern: a webhook that serves an HTML page.

```
[Webhook GET /dashboard] → [Respond with HTML]
```

**Use this as a starting point** for any page you want to serve from n8n.
Replace the placeholder HTML with your own content (see
`frontend/templates/` for full examples).

### 2. `form-to-nocodb.json` — Form Submission Handler

Receives form data via POST and creates a record in NocoDB.

```
[Webhook POST] → [Extract Fields] → [HTTP Request to NocoDB] → [Respond JSON]
```

**Great for:** contact forms, feedback forms, data entry, any page that
collects user input and stores it in a database.

### 3. `nocodb-crud-api.json` — Full CRUD API Proxy

A single endpoint that handles all CRUD operations (Create, Read, Update,
Delete) by routing based on the HTTP method.

```
[Webhook ALL /api/records] → [Switch by Method] → GET  → [List Records]   → [Respond]
                                                → POST → [Create Record]  → [Respond]
                                                → PATCH → [Update Record] → [Respond]
                                                → DELETE → [Delete Record] → [Respond]
```

**Great for:** building a backend API that your frontend JavaScript can
call for all data operations.

---

## How to Import a Workflow into n8n

### Method 1: Copy-Paste (Easiest)

1. Open the JSON file (e.g., `serve-dashboard.json`)
2. Copy the entire contents (Ctrl+A, Ctrl+C)
3. In your n8n instance, go to **Workflows** → **New Workflow**
4. Press **Ctrl+V** (or Cmd+V on Mac) anywhere on the canvas
5. The workflow nodes will appear on the canvas
6. Click **Save**

### Method 2: Import File

1. In your n8n instance, go to **Workflows**
2. Click the **⋯** menu → **Import from File**
3. Select the JSON file from your computer
4. The workflow will be created automatically

### Method 3: Via API (Programmatic)

```bash
# Using the wrapper script:
bash .claude/scripts/n8n.sh create-workflow "$(cat workflows/examples/serve-dashboard.json)"

# The script will return the created workflow with its new ID.
# Then activate it:
bash .claude/scripts/n8n.sh activate <workflow-id>
```

---

## How to Customize These Workflows

### Step 1: Replace `TABLE_ID`

The HTTP Request nodes use `TABLE_ID` as a placeholder. Replace it with
your actual NocoDB table ID:

1. Find your table ID: `bash .claude/scripts/noco.sh list-tables`
2. In the workflow JSON, search for `TABLE_ID` and replace with your
   actual table ID (e.g., `tbl_abc123xyz`)

### Step 2: Set Up Credentials

The HTTP Request nodes use `httpHeaderAuth` for NocoDB authentication.
In n8n:

1. Go to **Settings** → **Credentials** → **Add Credential**
2. Choose **Header Auth**
3. Set:
   - **Name:** `NocoDB API Token`
   - **Header Name:** `xc-token`
   - **Header Value:** your NocoDB API token
4. Save the credential
5. In each HTTP Request node, select this credential

### Step 3: Set Environment Variables

Some workflows use n8n environment variables (`$env.NOCODB_URL`, etc.).
Set these in your n8n instance:

1. Go to **Settings** → **Variables** (or set them in your n8n config)
2. Add:
   - `NOCODB_URL` — your NocoDB instance URL
   - `NOCODB_BASE_ID` — your base ID (starts with `p`)

### Step 4: Customize Fields

The example workflows use placeholder field names like `Name`, `Email`,
`Status`, and `Notes`. Update these to match your actual NocoDB table
columns.

### Step 5: Activate

After configuring, activate the workflow:
- In the n8n UI: Toggle the **Active** switch in the top-right corner
- Via API: `bash .claude/scripts/n8n.sh activate <workflow-id>`

---

## Validating Modified Workflows

After customizing a workflow, look up node documentation to verify your
configuration is correct:

```bash
# Check node properties/parameter schema:
bash .claude/scripts/mcp.sh props n8n-nodes-base.httpRequest

# Check node operations:
bash .claude/scripts/mcp.sh ops n8n-nodes-base.httpRequest

# Get full documentation for a node:
bash .claude/scripts/mcp.sh get n8n-nodes-base.webhook
```

This helps catch configuration errors before you deploy.

---

## Creating Your Own Workflows

1. **Search templates first** — there are 2,737 available:
   ```bash
   bash .claude/scripts/mcp.sh templates "your use case"
   ```

2. **Look up node documentation** before configuring any node:
   ```bash
   bash .claude/scripts/mcp.sh get n8n-nodes-base.webhook
   bash .claude/scripts/mcp.sh props n8n-nodes-base.webhook
   ```

3. **Save your workflows** to this directory for version control:
   ```bash
   bash .claude/scripts/n8n.sh get-workflow <id> > workflows/examples/my-workflow.json
   ```

---

## Further Reading

- **n8n Workflow Documentation:** https://docs.n8n.io/workflows/
- **n8n Node Reference:** https://docs.n8n.io/integrations/
- **n8n Webhook Node:** https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/
- **NocoDB REST API:** https://data-apis-v2.nocodb.com/
- **Architecture Guide:** See `docs/architecture.md` in this repo
