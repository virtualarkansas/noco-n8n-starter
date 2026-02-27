# Getting Started with NocoFlow Starter

Welcome! This guide walks you through setting up your development
environment and building your first NocoDB dashboard with n8n workflows,
all powered by Claude Code.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Using This Template](#using-this-template)
3. [Opening in Claude Code Web](#opening-in-claude-code-web)
4. [Session Setup](#session-setup)
5. [Choose Your Approach](#choose-your-approach)
6. [Your First Task: Build a Simple Dashboard](#your-first-task-build-a-simple-dashboard)
7. [Exporting and Importing Workflows](#exporting-and-importing-workflows)
8. [Where to Learn More](#where-to-learn-more)

---

## Prerequisites

### Required

- **GitHub account** — free tier is fine
- **Claude Pro subscription** — gives you access to Claude Code Web

### Optional (for live API connections)

- **NocoDB account** — either:
  - Cloud: Sign up at https://app.nocodb.com (free tier available)
  - Self-hosted: Run via Docker (https://docs.nocodb.com/getting-started/self-hosted/installation)
- **n8n account** — either:
  - Cloud: Sign up at https://n8n.io (free trial available)
  - Self-hosted: Run via Docker or npm (https://docs.n8n.io/hosting/)

**You don't need NocoDB or n8n to get started!** This template works
without them — you can build and test workflow JSON files, learn the
APIs, and explore node documentation using the built-in node database.
When you're ready to go live, add your API credentials.

---

## Using This Template

### Step 1: Create Your Repository

1. Go to the NocoFlow Starter template repository on GitHub
2. Click the green **"Use this template"** button
3. Select **"Create a new repository"**
4. Give it a name (e.g., `my-dashboard`, `project-tracker`)
5. Choose **Private** or **Public**
6. Click **"Create repository"**

You now have your own copy of the template with all the scripts,
configuration, and documentation.

### Step 2: Clone (Optional)

If you want to work locally in addition to Claude Code Web:

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME
```

---

## Opening in Claude Code Web

### Step 1: Open Claude Code

1. Go to https://claude.ai
2. Start a new conversation
3. Open Claude Code Web (available with Claude Pro)

### Step 2: Connect Your Repository

Claude Code Web can access your GitHub repositories. When you start a
new session, connect it to the repository you created from this template.

### Step 3: Verify the Setup

Ask Claude to verify the project structure:

```
Can you check that all the project files are in place? List the contents
of .claude/scripts/ and confirm CLAUDE.md exists.
```

Claude should see:
- `CLAUDE.md` — project context (loaded automatically)
- `.claude/settings.json` — security permissions
- `.claude/scripts/` — 6 wrapper scripts
- `docs/` — reference documentation
- `package.json` — project configuration

---

## Session Setup

Each time you start a new Claude Code Web session, run through this
setup sequence. You can ask Claude to do it for you!

### Step 1: Verify the Node Database

The SessionStart hook automatically downloads the n8n node database
(`data/nodes.db`) when you open the repo. You can verify it's ready:

```
Can you check that the node database is available?
```

Claude will run:
```bash
bash .claude/scripts/mcp.sh stats
```

This shows statistics for the SQLite database containing 1,236 n8n node
docs and 2,737 workflow templates. No server needed — queries run directly
via sqlite3.

### Step 2: Configure API Keys (Optional)

If you have NocoDB and/or n8n credentials, provide them to Claude:

```
Please set up my environment with these credentials:
- NocoDB URL: https://app.nocodb.com
- NocoDB Token: <your-token>
- NocoDB Base ID: p_abc123
- n8n URL: https://my-name.app.n8n.cloud
- n8n API Key: <your-key>
```

Claude will run the setup script to store them securely in `.env`
(which is gitignored — never committed).

**Skip this step** if you don't have credentials yet. You can still
build workflow JSON files and learn the tools.

### Step 3: Verify Connections (Optional)

If you configured credentials:

```
Can you verify that the NocoDB and n8n connections are working?
```

Claude will test the connections:
```bash
bash .claude/scripts/noco.sh list-bases
bash .claude/scripts/n8n.sh health
```

---

## Choose Your Approach

Before building anything, decide which dashboard approach fits your needs.
This template supports two fundamentally different paths:

### NocoDB Native Dashboard (Faster, No Code)

Use NocoDB's built-in views as your dashboard. NocoDB provides grid,
gallery, kanban, form, and calendar views out of the box. You can share
them via public links for read-only access.

**Best for:** internal tools, data management, rapid prototyping, and
situations where you want a working dashboard in minutes instead of hours.

**What you need:** just a NocoDB instance (n8n is optional — only needed
for automations like sending emails on form submit or syncing to other
services).

**What you get:**
- Shared grid/kanban/gallery views via public links
- Built-in form views for data entry
- Button columns that trigger n8n webhooks for row-level actions
- Record webhooks for automatic triggers (after insert/update/delete)

### Custom HTML Frontend (More Flexible, More Work)

Build HTML/CSS/JavaScript pages served by n8n webhook nodes. Your frontend
calls n8n webhook endpoints via fetch(), and n8n handles the backend logic
(reading/writing NocoDB, calling external APIs).

**Best for:** custom apps, public-facing UIs, branded experiences, and
cases where you need full control over design, layout, and interactivity.

**What you need:** both NocoDB (database) and n8n (web server + backend).

**What you get:**
- Full control over HTML, CSS, and JavaScript
- Custom layouts, charts, and interactive components
- Any design you can build with web technologies

**Not sure?** Start with NocoDB Native — you can always add a custom
frontend later. The database and n8n workflows you build are the same
either way.

See `docs/nocodb-dashboard-patterns.md` for the full NocoDB native guide
and `docs/n8n-webhook-frontend.md` for the custom frontend pattern.

---

## Your First Task: Build a Simple Dashboard

Let's build a simple task dashboard to see all the pieces working
together. Just ask Claude!

### Path A: NocoDB Native Dashboard

If you have a NocoDB instance configured:

```
Build me a task tracker using NocoDB's native views:
1. Create a "Tasks" table with columns: Name, Status (single select),
   Priority (number), Due Date, Notes
2. Add 5 sample tasks with different statuses
3. Create a Kanban view grouped by Status
4. Create a Form view for adding new tasks
5. Show me how to share these views via public links
```

If you also have n8n and want automations:

```
Also set up an n8n workflow that triggers when a task status changes
to "Done" — just log the record for now, and later we can add email
notifications.
```

### Path B: Custom HTML Frontend

If you have both NocoDB and n8n configured:

```
Build me a custom task dashboard:
1. Create a "Tasks" table in NocoDB with columns: Name, Status, Priority
2. Add 5 sample tasks
3. Create an n8n workflow that:
   - Serves an HTML dashboard page at /webhook/dashboard
   - Has an API endpoint at /webhook/api/tasks that reads from NocoDB
   - The dashboard should display tasks in a styled table
   - Include a form to create new tasks
```

### Path C: Learning Mode (No Live Services)

If you're just exploring without credentials:

```
Show me what a task dashboard workflow would look like:
1. Search the node database for webhook and HTTP request documentation
2. Build the workflow JSON for a dashboard that serves HTML and proxies
   to a NocoDB API
3. Save it to workflows/examples/task-dashboard.json
4. Explain each node and connection
```

### What Claude Will Do

1. **Search templates** — Check if a similar workflow already exists in the database
2. **Look up nodes** — Get correct configuration for each node type via sqlite3
3. **Build the workflow** — Create valid JSON with proper connections
4. **Deploy** — Push to n8n (if configured) and activate
5. **Test** — Verify the webhook responds correctly

---

## Exporting and Importing Workflows

### Exporting (Saving Workflow JSON)

Save your workflows as JSON files for version control:

```
Please export the dashboard workflow and save it to
workflows/examples/task-dashboard.json
```

Claude will:
```bash
bash .claude/scripts/n8n.sh get-workflow <id>
```

And save the output to the file.

### Importing (Loading a Saved Workflow)

To deploy a saved workflow to n8n:

```
Please import the workflow from workflows/examples/task-dashboard.json
and activate it.
```

Claude will:
```bash
bash .claude/scripts/n8n.sh create-workflow "$(cat workflows/examples/task-dashboard.json)"
bash .claude/scripts/n8n.sh activate <new-id>
```

### Why Export Workflows?

- **Version control** — track changes in git
- **Sharing** — share workflows with teammates
- **Backup** — recover if a workflow is accidentally deleted
- **Templates** — reuse patterns across projects

---

## Where to Learn More

### NocoDB

- **Documentation:** https://docs.nocodb.com/
- **REST API (v2):** https://data-apis-v2.nocodb.com/
- **All APIs:** https://all-apis.nocodb.com/
- **Community:** https://community.nocodb.com/
- **In this project:** See `docs/nocodb-api-guide.md`

### n8n

- **Documentation:** https://docs.n8n.io/
- **REST API:** https://docs.n8n.io/api/
- **Node Reference:** https://docs.n8n.io/integrations/
- **Community:** https://community.n8n.io/
- **In this project:** See `docs/n8n-api-guide.md`

### n8n-mcp (Node Documentation Database)

- **GitHub:** https://github.com/czlonkowski/n8n-mcp
- **Usage in this project:** See the "Available Tools" section in `CLAUDE.md`
- **Query it:** `bash .claude/scripts/mcp.sh search <query>`

### n8n-skills (Specialized Development Skills)

- **What they are:** 7 specialized skills that teach Claude correct n8n
  expression syntax, workflow patterns, validation techniques, and code
  node usage
- **Location in this project:** `.claude/skills/` (downloaded during setup)
- **They activate automatically** when Claude detects relevant context

### Webhook Frontend Pattern

- **In this project:** See `docs/n8n-webhook-frontend.md`
- **n8n Webhook docs:** https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/

### Architecture

- **In this project:** See `docs/architecture.md`
- **Understand how the pieces fit together** before building complex workflows
