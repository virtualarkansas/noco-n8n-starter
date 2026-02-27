# System Architecture

This document explains how the three main components of a NocoFlow project
connect and work together: **NocoDB** (database), **n8n** (workflow engine),
and your **Frontend** (HTML/CSS/JS served to users).

---

## The Three Components

```
┌─────────────────────┐      ┌──────────────────────┐      ┌─────────────────────┐
│                     │      │                      │      │                     │
│   Frontend (HTML)   │─────▶│   n8n Webhooks       │─────▶│   NocoDB            │
│                     │◀─────│   (Workflow Engine)   │◀─────│   (Database)        │
│  • HTML pages       │      │                      │      │                     │
│  • CSS styling      │      │  • Webhook nodes     │      │  • Tables & views   │
│  • JavaScript       │      │  • HTTP Request nodes│      │  • REST API (v3)    │
│  • fetch() calls    │      │  • Code nodes        │      │  • Filtering/sort   │
│                     │      │  • Logic & routing   │      │  • Linked records   │
└─────────────────────┘      └──────────────────────┘      └─────────────────────┘
         │                             │
         │  User interacts             │  n8n calls external
         │  via browser                │  services too
         ▼                             ▼
    Browser / User              External APIs
                                (Slack, Email, etc.)
```

### 1. NocoDB — The Database

NocoDB is a spreadsheet-like database with a powerful REST API. Think of it
as "Airtable but open-source." It stores all your structured data.

**What it does:**
- Stores records in tables (like rows in a spreadsheet)
- Provides views (grid, gallery, kanban, form)
- Exposes a REST API for reading/writing data programmatically
- Handles filtering, sorting, pagination, and linked records

**In this project, NocoDB is your single source of truth for data.**

### 2. n8n — The Workflow Engine

n8n is a workflow automation platform. In this project, it serves two roles:

**Role A: Web server** — n8n Webhook nodes can receive HTTP requests and
respond with HTML. This is how your frontend gets served to users.

**Role B: Backend logic** — n8n workflows handle all the business logic:
reading from NocoDB, processing data, calling external APIs, and returning
results to the frontend.

**In this project, n8n is both your web server AND your backend.**

### 3. Frontend — The User Interface

Plain HTML/CSS/JavaScript pages that users see in their browser. These are
served by n8n webhook nodes and communicate back to n8n via fetch() calls.

**What it does:**
- Displays data to users (tables, charts, forms)
- Accepts user input (forms, buttons, filters)
- Calls n8n webhook endpoints to read/write data

**In this project, the frontend is vanilla JS — no build step required.**

---

## Data Flow: Loading a Dashboard

Here's what happens step-by-step when a user visits your dashboard:

```
User's Browser                    n8n                         NocoDB
     │                             │                             │
     │  1. GET /webhook/dashboard  │                             │
     │────────────────────────────▶│                             │
     │                             │                             │
     │  2. Respond with HTML page  │                             │
     │◀────────────────────────────│                             │
     │                             │                             │
     │  (Browser renders HTML,     │                             │
     │   JavaScript starts)        │                             │
     │                             │                             │
     │  3. fetch('/webhook/api/    │                             │
     │     records')               │                             │
     │────────────────────────────▶│                             │
     │                             │  4. GET /api/v3/{base}/     │
     │                             │     {table}?limit=25        │
     │                             │────────────────────────────▶│
     │                             │                             │
     │                             │  5. JSON response with      │
     │                             │     records                 │
     │                             │◀────────────────────────────│
     │                             │                             │
     │  6. JSON response with      │                             │
     │     records                 │                             │
     │◀────────────────────────────│                             │
     │                             │                             │
     │  (JavaScript renders the    │                             │
     │   data into a table)        │                             │
     │                             │                             │
```

**Step by step:**
1. User navigates to your n8n webhook URL in their browser
2. n8n's Webhook node catches the GET request, and the Respond to Webhook
   node sends back an HTML page
3. The HTML page loads in the browser. Its JavaScript runs and calls another
   n8n webhook endpoint to fetch data
4. n8n receives the data request and uses an HTTP Request node to call the
   NocoDB API
5. NocoDB returns the requested records as JSON
6. n8n passes the JSON response back to the browser, where JavaScript
   renders it into the page

---

## Data Flow: Submitting a Form

Here's what happens when a user fills out and submits a form:

```
User's Browser                    n8n                         NocoDB
     │                             │                             │
     │  1. POST /webhook/api/      │                             │
     │     records                 │                             │
     │     Body: {"Name":"Alice",  │                             │
     │            "Email":"..."}   │                             │
     │────────────────────────────▶│                             │
     │                             │                             │
     │                             │  2. (Optional) Validate     │
     │                             │     data in Code node       │
     │                             │                             │
     │                             │  3. POST /api/v3/{base}/    │
     │                             │     {table}                 │
     │                             │     Body: {"Name":"Alice"}  │
     │                             │────────────────────────────▶│
     │                             │                             │
     │                             │  4. Created record          │
     │                             │     {Id: 1, Name: "Alice"}  │
     │                             │◀────────────────────────────│
     │                             │                             │
     │  5. JSON: {"success":true,  │                             │
     │     "record":{...}}         │                             │
     │◀────────────────────────────│                             │
     │                             │                             │
     │  (JavaScript shows success  │                             │
     │   message, refreshes list)  │                             │
```

**Step by step:**
1. User clicks "Submit" — JavaScript sends a POST request with form data
   to an n8n webhook endpoint
2. n8n can optionally validate the data (check required fields, sanitize
   input) using a Code node or If node
3. n8n sends the validated data to NocoDB's create-record endpoint
4. NocoDB creates the record and returns it
5. n8n sends a success response back to the browser
6. JavaScript shows a success message and optionally refreshes the data

---

## Where the Wrapper Scripts Fit In

During development with Claude Code, you use the wrapper scripts in
`.claude/scripts/` to interact with NocoDB and n8n **directly** — without
building workflows first.

```
During Development (with Claude Code):

  Claude Code
       │
       ├── bash .claude/scripts/noco.sh list-tables
       │   └── Reads .env → calls NocoDB API → shows tables
       │
       ├── bash .claude/scripts/n8n.sh list-workflows
       │   └── Reads .env → calls n8n API → shows workflows
       │
       └── bash .claude/scripts/mcp.sh search_nodes '{"query":"webhook"}'
           └── Queries local n8n-mcp server → returns node documentation
```

**Why wrapper scripts?**
- They read API tokens from `.env` so tokens are never exposed in commands
- They provide a simple interface for common operations
- Claude Code calls them instead of crafting raw curl commands
- They match the security rules in CLAUDE.md

**Important:** The wrapper scripts are for *development*. In production,
your n8n workflows handle all API calls using HTTP Request nodes with
proper n8n credentials.

---

## The Knowledge Layer: n8n-mcp

The n8n-mcp server (started with `bash .claude/scripts/start-mcp.sh`) is a
local reference database containing documentation for 1,084 n8n nodes and
2,646 real-world template configurations.

```
Building a Workflow:

  You describe what you want
       │
       ▼
  Claude searches n8n-mcp for:
  ├── Matching templates (2,709 available)
  ├── Node documentation
  └── Configuration examples
       │
       ▼
  Claude builds workflow JSON using:
  ├── Correct node types
  ├── Validated configurations
  └── Real-world patterns
       │
       ▼
  Workflow validated via n8n-mcp
       │
       ▼
  Deployed to n8n via wrapper script
```

**Why this matters:** n8n node types and their configurations are complex.
Without n8n-mcp, it's easy to use wrong parameter names, miss required
fields, or build workflows that fail at runtime. The n8n-mcp server
provides the knowledge needed to build correct workflows the first time.

---

## Summary

| Component | Role | How Claude Interacts |
|-----------|------|---------------------|
| NocoDB | Database (stores data) | Via `noco.sh` wrapper script |
| n8n | Web server + backend logic | Via `n8n.sh` wrapper script |
| Frontend | User interface (HTML/JS) | Creates files directly |
| n8n-mcp | Node docs + validation | Via `mcp.sh` wrapper script |

The flow is always: **User → Frontend → n8n → NocoDB** (and back).
Claude Code helps you build all three layers using the wrapper scripts
and n8n-mcp for guidance.
