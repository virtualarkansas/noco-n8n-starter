# NocoFlow Starter

A starter template for building NocoDB dashboards and n8n workflow automations using Claude Code Web.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![n8n](https://img.shields.io/badge/n8n-workflow%20automation-FF6D5A?logo=n8n&logoColor=white)](https://n8n.io)
[![NocoDB](https://img.shields.io/badge/NocoDB-database-7F5AF0)](https://nocodb.com)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Web-D97757?logo=anthropic&logoColor=white)](https://claude.ai/code)

---

## What This Is

This is a GitHub template repository. Click **"Use this template"** to create your own copy, then open it in Claude Code Web to start building dashboards and automations with AI assistance.

The template provides a complete development environment for building web dashboards backed by NocoDB (an open-source database with a spreadsheet UI) and automated with n8n (a workflow automation platform). Your frontend is plain HTML/CSS/JavaScript served directly by n8n webhook nodes, NocoDB stores your data, and n8n handles all the backend logic — fetching records, processing form submissions, calling external APIs, and more.

Everything here is designed for Claude Code Web at [claude.ai/code](https://claude.ai/code). The project includes [n8n-mcp](https://github.com/czlonkowski/n8n-mcp) integration for intelligent workflow building (1,084 nodes, 2,709 templates), [n8n-skills](https://github.com/czlonkowski/n8n-skills) for correct expression syntax and workflow patterns, wrapper scripts that keep your API tokens safe, and thorough documentation written for beginners. You describe what you want to build, and Claude handles the rest — looking up the right nodes, validating configurations, generating workflow JSON, and deploying to your n8n instance.

## Architecture

```
┌─────────────────────┐      ┌──────────────────────┐      ┌─────────────────────┐
│                     │      │                      │      │                     │
│   Frontend (HTML)   │─────▶│   n8n Webhooks       │─────▶│   NocoDB            │
│                     │◀─────│   (Workflow Engine)   │◀─────│   (Database)        │
│  • HTML/CSS/JS      │      │  • Serves pages      │      │  • Tables & views   │
│  • Tailwind CSS     │      │  • API proxy         │      │  • REST API (v3)    │
│  • fetch() calls    │      │  • Business logic    │      │  • Filtering/sort   │
│                     │      │  • Automations       │      │  • Linked records   │
└─────────────────────┘      └──────────────────────┘      └─────────────────────┘
```

**Frontend** is vanilla HTML/CSS/JavaScript served by n8n webhook nodes. No build step, no framework — just files that work in any modern browser. Tailwind CSS is loaded from a CDN for styling.

**n8n** acts as both your web server and backend. Webhook nodes receive HTTP requests and serve HTML pages or JSON APIs. Workflow nodes handle data processing, validation, and communication with NocoDB and external services.

**NocoDB** is your database. It provides a spreadsheet-like UI for managing data and a REST API for programmatic access. Think of it as a self-hostable alternative to Airtable.

## Quick Start

### Prerequisites

- **GitHub account** (free)
- **Claude Pro or Max subscription** for Claude Code Web access
- **Optional:** NocoDB instance — free cloud tier at [nocodb.com](https://nocodb.com) or self-hosted
- **Optional:** n8n instance — free trial at [n8n.io](https://n8n.io) or self-hosted

You don't need NocoDB or n8n to get started. The template works without them — you can build workflow JSON files, explore node documentation, and learn the patterns. Add live credentials when you're ready to deploy.

### 1. Use This Template

Click the green **"Use this template"** button at the top of this repository, then **"Create a new repository"**. Give it a name, choose public or private, and create it.

### 2. Open in Claude Code Web

Go to [claude.ai/code](https://claude.ai/code) and start a remote session connected to your new repository.

### 3. Set Up Your Session

Paste this into Claude Code to initialize the development environment:

```
Download n8n-skills for workflow pattern guidance, start the n8n-mcp
documentation server, and make the wrapper scripts executable:

git clone https://github.com/czlonkowski/n8n-skills.git /tmp/n8n-skills
mkdir -p .claude/skills
cp /tmp/n8n-skills/dist/*.md .claude/skills/
rm -rf /tmp/n8n-skills

chmod +x .claude/scripts/*.sh
bash .claude/scripts/start-mcp.sh
```

If you have NocoDB and/or n8n credentials, also run:

```
bash .claude/scripts/setup-env.sh "NOCODB_URL" "NOCODB_TOKEN" "BASE_ID" "N8N_URL" "N8N_KEY"
```

### 4. Start Building

Ask Claude to help you build your first project. Here are some ideas:

- *"Build me a task tracker dashboard with a table and add-task form"*
- *"Create an n8n workflow that receives webhook POSTs and stores them in NocoDB"*
- *"Set up a CRUD API proxy so my frontend can read and write NocoDB records"*
- *"Show me how to serve an HTML page from an n8n webhook"*

## What's Included

### Wrapper Scripts (`.claude/scripts/`)

| Script | Purpose |
|--------|---------|
| `setup-env.sh` | Writes API credentials to `.env` from positional arguments |
| `start-mcp.sh` | Starts the n8n-mcp documentation server on port 3001 |
| `stop-mcp.sh` | Stops the n8n-mcp server |
| `mcp.sh` | Queries n8n-mcp for node docs, templates, and validation |
| `noco.sh` | NocoDB REST API wrapper (list, create, update, delete records) |
| `n8n.sh` | n8n REST API wrapper (manage workflows, executions) |

### Documentation (`docs/`)

| File | Covers |
|------|--------|
| `architecture.md` | System diagram, data flows, how the three layers connect |
| `nocodb-api-guide.md` | NocoDB REST API v3 — full CRUD, filtering, sorting, pagination |
| `n8n-api-guide.md` | n8n REST API — workflow management, executions, webhook URLs |
| `n8n-webhook-frontend.md` | Serving HTML from webhooks, iframe sandbox, CORS, examples |
| `getting-started.md` | Step-by-step setup guide for first-time users |

### Example Workflows (`workflows/examples/`)

| File | Demonstrates |
|------|-------------|
| `serve-dashboard.json` | Webhook GET → Respond with HTML (simplest pattern) |
| `form-to-nocodb.json` | Webhook POST → Extract fields → Create NocoDB record |
| `nocodb-crud-api.json` | Single endpoint with Switch routing for full CRUD operations |

These are valid n8n workflow JSON files. Import them directly into your n8n instance via copy-paste or the API.

### Frontend Templates (`frontend/templates/`)

| File | Description |
|------|-------------|
| `base.html` | Base HTML structure with Tailwind CDN, nav, footer, `apiFetch()` helper |
| `dashboard.html` | Data table with refresh, modal form, loading/error states |
| `form.html` | Standalone form with client-side validation and async submission |

### Custom Node Scaffold (`n8n-nodes/`)

A starter TypeScript project for building custom n8n nodes, with an annotated example node and credential type. See [n8n's creating nodes docs](https://docs.n8n.io/integrations/creating-nodes/) for the full guide.

### Utility Scripts (`scripts/`)

| File | Purpose |
|------|---------|
| `validate-env.js` | Tests NocoDB and n8n connectivity, reports status |
| `sync-workflows.js` | Export workflows from n8n to local JSON, or import local JSON into n8n |

## How It Works in Claude Code Web

When you open this project in Claude Code Web, four layers work together to give Claude the context it needs to build correct workflows and dashboards:

**Layer 1: CLAUDE.md** is loaded automatically at the start of every conversation. It contains the project overview, security rules, API references, node type lists, and coding conventions. This is Claude's primary context about your project.

**Layer 2: n8n-skills** are markdown files in `.claude/skills/` that teach Claude correct n8n expression syntax, workflow patterns, validation techniques, and Code node usage. They activate automatically when Claude detects relevant context — for example, when you ask it to build a workflow with expressions, the expression syntax skill kicks in.

**Layer 3: n8n-mcp** is a local HTTP server (port 3001) that provides searchable access to documentation for 1,084 n8n nodes and 2,709 real-world workflow templates. Claude queries it via the `mcp.sh` wrapper script to look up node configurations, find matching templates, and validate workflows before deployment.

**Layer 4: Wrapper scripts** in `.claude/scripts/` give Claude safe access to your NocoDB and n8n APIs. They read tokens from `.env` internally, so Claude never sees or handles your raw API keys. Claude calls the scripts; the scripts handle authentication.

**Important:** Claude Code Web containers are ephemeral. Your code is persisted in your GitHub repository, but the local environment (n8n-mcp server, skills files, `.env` credentials) resets each session. Run the setup commands from [Session Setup](#session-setup-repeat-each-time) at the start of each new session.

## Session Setup (Repeat Each Time)

Copy and paste this block at the start of each Claude Code Web session:

```
Set up the development environment:

git clone https://github.com/czlonkowski/n8n-skills.git /tmp/n8n-skills
mkdir -p .claude/skills
cp /tmp/n8n-skills/dist/*.md .claude/skills/
rm -rf /tmp/n8n-skills

chmod +x .claude/scripts/*.sh
bash .claude/scripts/start-mcp.sh

# Only if you have credentials:
# bash .claude/scripts/setup-env.sh "NOCODB_URL" "TOKEN" "BASE_ID" "N8N_URL" "API_KEY"
```

This downloads the latest n8n-skills, starts the n8n-mcp documentation server, and optionally configures your API credentials.

## Security

This template takes a defense-in-depth approach to credential safety:

**`.env` files are gitignored** and never committed to your repository. The `.gitignore` file explicitly excludes `.env` and `.env.*` while allowing `.env.example` (which contains no secrets).

**Wrapper scripts isolate API tokens from Claude.** Instead of constructing curl commands with embedded tokens, Claude calls scripts like `noco.sh` and `n8n.sh` that read credentials from `.env` internally. Claude never sees the token values.

**`.claude/settings.json` blocks direct `.env` reads.** Even if Claude tried to read your `.env` file directly, the permission deny rules would prevent it.

**A note about cloud AI tools:** When you provide API credentials in a Claude Code Web session, the data passes through Anthropic's systems as part of the conversation. This is inherent to all cloud-based AI tools. The wrapper scripts minimize exposure by keeping tokens out of conversation text, but if you're working with highly sensitive credentials, consider using a self-hosted setup instead.

## Resources

**NocoDB**
- [Documentation](https://docs.nocodb.com/)
- [REST API Reference](https://data-apis-v2.nocodb.com/)
- [All APIs](https://all-apis.nocodb.com/)

**n8n**
- [Documentation](https://docs.n8n.io/)
- [API Reference](https://docs.n8n.io/api/)
- [Node Reference](https://docs.n8n.io/integrations/)
- [Community Forum](https://community.n8n.io/)

**n8n-mcp** — Node documentation and workflow validation server
- [GitHub](https://github.com/czlonkowski/n8n-mcp)

**n8n-skills** — Workflow pattern guidance for AI assistants
- [GitHub](https://github.com/czlonkowski/n8n-skills)
- [Website](https://n8n-skills.com)

## Contributing

Contributions are welcome! If you have ideas for new example workflows, better documentation, or improvements to the scripts, feel free to open an issue or submit a pull request.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-improvement`)
3. Make your changes
4. Commit with a descriptive message
5. Push to your branch and open a pull request

## License

[MIT](LICENSE) — use this template for anything you want.
