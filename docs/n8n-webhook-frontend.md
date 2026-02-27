# Serving Frontend from n8n Webhooks

This guide explains how to use n8n webhook nodes as a web server to serve
HTML pages, handle form submissions, and build interactive dashboards.

---

## Table of Contents

1. [Basic Pattern: Webhook → HTML](#basic-pattern-webhook--html)
2. [Embedding Dynamic Data](#embedding-dynamic-data)
3. [The Iframe Sandboxing Issue](#the-iframe-sandboxing-issue)
4. [Complete Example: Dashboard](#complete-example-dashboard)
5. [Complete Example: Form Submission](#complete-example-form-submission)
6. [CORS Considerations](#cors-considerations)
7. [Multiple Pages Pattern](#multiple-pages-pattern)
8. [Security Best Practices](#security-best-practices)

---

## Basic Pattern: Webhook → HTML

The simplest way to serve a web page from n8n uses just two nodes:

```
[Webhook] ──▶ [Respond to Webhook]
  GET /page       HTML response
```

### Node 1: Webhook

Configure the Webhook node to listen for GET requests:

- **HTTP Method:** GET
- **Path:** `dashboard` (this becomes the URL path)
- **Response Mode:** Using 'Respond to Webhook' Node

### Node 2: Respond to Webhook

Configure the response node to return HTML:

- **Respond With:** Text
- **Response Body:** Your HTML content
- **Response Headers:** Add a header:
  - **Name:** `Content-Type`
  - **Value:** `text/html`

### Resulting URL

```
# Production (after activating the workflow):
https://your-n8n.app.n8n.cloud/webhook/dashboard

# Test mode (in the workflow editor):
https://your-n8n.app.n8n.cloud/webhook-test/dashboard
```

### Minimal Example

Here's the simplest possible HTML response:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>My Dashboard</title>
</head>
<body>
  <h1>Hello from n8n!</h1>
  <p>This page is served by an n8n webhook.</p>
</body>
</html>
```

---

## Embedding Dynamic Data

You can use n8n expressions to inject data into your HTML before sending it.

### Using Expressions in the Response Body

In the Respond to Webhook node's response body, you can use n8n expressions
to embed data from previous nodes:

```html
<h1>Welcome, {{ $json.userName }}</h1>
<p>You have {{ $json.taskCount }} tasks.</p>
```

### Pattern: Fetch Data → Inject into HTML

```
[Webhook GET] ──▶ [HTTP Request to NocoDB] ──▶ [Code: Build HTML] ──▶ [Respond]
```

In the Code node, build the HTML with data:

```javascript
// Code node — builds HTML with data from NocoDB
const records = $input.all();

let tableRows = '';
for (const item of records) {
  tableRows += `
    <tr>
      <td>${item.json.Name}</td>
      <td>${item.json.Status}</td>
      <td>${item.json.Priority}</td>
    </tr>`;
}

const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Task Dashboard</title>
</head>
<body>
  <h1>Tasks</h1>
  <table>
    <thead>
      <tr><th>Name</th><th>Status</th><th>Priority</th></tr>
    </thead>
    <tbody>${tableRows}</tbody>
  </table>
</body>
</html>`;

return [{ json: { html } }];
```

Then in the Respond to Webhook node, set the response body to:
`{{ $json.html }}`

---

## The Iframe Sandboxing Issue

**Important:** Starting with n8n version 1.103.0, HTML responses from
webhooks are wrapped in a **sandboxed iframe** for security.

### What This Means

Your HTML page runs inside an iframe with restricted permissions. The
following features are **NOT available**:

| Feature | Status | Workaround |
|---------|--------|------------|
| `localStorage` | Blocked | Use URL parameters or server-side state |
| `sessionStorage` | Blocked | Use URL parameters or server-side state |
| `window.top` | Blocked | Not needed — treat page as standalone |
| `document.cookie` | Blocked | Embed tokens in HTML instead |
| Relative URLs | Unreliable | Always use absolute URLs |
| Parent page access | Blocked | Not available in sandbox |

### Rules for Working Within the Sandbox

1. **Always use absolute URLs** for all links, form actions, and fetch calls:
   ```javascript
   // WRONG — relative URL may not resolve correctly:
   fetch('/webhook/api/data')

   // CORRECT — absolute URL:
   fetch('https://your-n8n.app.n8n.cloud/webhook/api/data')
   ```

2. **No localStorage or sessionStorage:**
   ```javascript
   // WRONG — will fail silently or throw error:
   localStorage.setItem('token', 'abc123');

   // CORRECT — embed state in the page or URL:
   const token = '{{ $json.token }}';  // injected by n8n
   ```

3. **Authentication via embedded tokens:**
   ```html
   <!-- Embed a short-lived token directly in the HTML -->
   <script>
     const API_TOKEN = '{{ $json.sessionToken }}';

     // Use it in fetch calls:
     fetch('https://your-n8n.app.n8n.cloud/webhook/api/data', {
       headers: { 'Authorization': `Bearer ${API_TOKEN}` }
     });
   </script>
   ```

4. **Forms must POST to absolute URLs:**
   ```html
   <!-- WRONG: -->
   <form action="/webhook/submit">

   <!-- CORRECT: -->
   <form action="https://your-n8n.app.n8n.cloud/webhook/submit">
   ```

---

## Complete Example: Dashboard

This example shows a full dashboard that loads data from NocoDB via n8n.

### Workflow Structure

```
[Webhook GET /dashboard] ──▶ [Respond with HTML]

[Webhook GET /api/tasks] ──▶ [HTTP Request to NocoDB] ──▶ [Respond with JSON]
```

Two webhook endpoints: one serves the HTML page, the other serves data
as a JSON API.

### The HTML Page

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Task Dashboard</title>
  <style>
    /* Simple, clean styling */
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: system-ui, sans-serif; padding: 2rem; background: #f5f5f5; }
    h1 { margin-bottom: 1rem; color: #333; }

    table { width: 100%; border-collapse: collapse; background: white;
            border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
    th { background: #4f46e5; color: white; padding: 0.75rem 1rem; text-align: left; }
    td { padding: 0.75rem 1rem; border-bottom: 1px solid #eee; }
    tr:hover { background: #f9fafb; }

    .loading { color: #666; font-style: italic; }
    .error { color: #dc2626; padding: 1rem; background: #fef2f2; border-radius: 8px; }
    .badge { padding: 0.25rem 0.5rem; border-radius: 4px; font-size: 0.85rem; }
    .badge-active { background: #dcfce7; color: #166534; }
    .badge-done { background: #e0e7ff; color: #3730a3; }
  </style>
</head>
<body>
  <h1>Task Dashboard</h1>
  <div id="content"><p class="loading">Loading tasks...</p></div>

  <script>
    // IMPORTANT: Use the absolute URL to your n8n instance
    const N8N_BASE = 'https://your-n8n.app.n8n.cloud/webhook';

    // Load tasks when the page opens
    async function loadTasks() {
      const content = document.getElementById('content');

      try {
        // Call the JSON API endpoint
        const response = await fetch(`${N8N_BASE}/api/tasks`);

        // Check for errors
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const data = await response.json();
        const records = data.list || data;

        // Build the HTML table
        if (records.length === 0) {
          content.innerHTML = '<p>No tasks found. Create one!</p>';
          return;
        }

        let html = `
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Status</th>
                <th>Priority</th>
              </tr>
            </thead>
            <tbody>`;

        for (const record of records) {
          const statusClass = record.Status === 'Done' ? 'badge-done' : 'badge-active';
          html += `
              <tr>
                <td>${record.Name}</td>
                <td><span class="badge ${statusClass}">${record.Status}</span></td>
                <td>${record.Priority || '-'}</td>
              </tr>`;
        }

        html += `
            </tbody>
          </table>`;

        content.innerHTML = html;

      } catch (error) {
        content.innerHTML = `<div class="error">Failed to load tasks: ${error.message}</div>`;
      }
    }

    // Run on page load
    loadTasks();
  </script>
</body>
</html>
```

---

## Complete Example: Form Submission

This example shows a form that creates a new record via n8n and NocoDB.

### Workflow Structure

```
[Webhook GET /form]  ──▶ [Respond with HTML form]

[Webhook POST /api/tasks] ──▶ [HTTP Request: POST to NocoDB] ──▶ [Respond with JSON]
```

### The HTML Form

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>New Task</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: system-ui, sans-serif; padding: 2rem; background: #f5f5f5; }
    h1 { margin-bottom: 1.5rem; color: #333; }

    .form-group { margin-bottom: 1rem; }
    label { display: block; margin-bottom: 0.25rem; font-weight: 600; color: #555; }
    input, select { width: 100%; padding: 0.5rem; border: 1px solid #ddd;
                    border-radius: 4px; font-size: 1rem; }
    button { background: #4f46e5; color: white; border: none; padding: 0.75rem 1.5rem;
             border-radius: 4px; font-size: 1rem; cursor: pointer; margin-top: 0.5rem; }
    button:hover { background: #4338ca; }
    button:disabled { background: #9ca3af; cursor: not-allowed; }

    .message { padding: 1rem; border-radius: 8px; margin-top: 1rem; }
    .success { background: #dcfce7; color: #166534; }
    .error { background: #fef2f2; color: #dc2626; }
  </style>
</head>
<body>
  <h1>Create New Task</h1>

  <form id="taskForm">
    <div class="form-group">
      <label for="name">Task Name</label>
      <input type="text" id="name" name="name" required placeholder="What needs to be done?">
    </div>

    <div class="form-group">
      <label for="status">Status</label>
      <select id="status" name="status">
        <option value="Todo">Todo</option>
        <option value="In Progress">In Progress</option>
        <option value="Done">Done</option>
      </select>
    </div>

    <div class="form-group">
      <label for="priority">Priority (1-5)</label>
      <input type="number" id="priority" name="priority" min="1" max="5" value="3">
    </div>

    <button type="submit" id="submitBtn">Create Task</button>
  </form>

  <div id="message"></div>

  <script>
    // IMPORTANT: Use the absolute URL to your n8n instance
    const N8N_BASE = 'https://your-n8n.app.n8n.cloud/webhook';

    document.getElementById('taskForm').addEventListener('submit', async (e) => {
      // Prevent default form submission (which would navigate away)
      e.preventDefault();

      const submitBtn = document.getElementById('submitBtn');
      const messageDiv = document.getElementById('message');

      // Disable button while submitting
      submitBtn.disabled = true;
      submitBtn.textContent = 'Creating...';

      // Gather form data
      const formData = {
        Name: document.getElementById('name').value,
        Status: document.getElementById('status').value,
        Priority: parseInt(document.getElementById('priority').value, 10)
      };

      try {
        // Send data to the n8n webhook endpoint
        const response = await fetch(`${N8N_BASE}/api/tasks`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(formData)
        });

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const result = await response.json();

        // Show success message
        messageDiv.innerHTML = `<div class="message success">
          Task "${formData.Name}" created successfully!
        </div>`;

        // Reset the form
        document.getElementById('taskForm').reset();

      } catch (error) {
        // Show error message
        messageDiv.innerHTML = `<div class="message error">
          Failed to create task: ${error.message}
        </div>`;
      } finally {
        // Re-enable the button
        submitBtn.disabled = false;
        submitBtn.textContent = 'Create Task';
      }
    });
  </script>
</body>
</html>
```

### How the POST Webhook Handles It

The n8n workflow for the POST endpoint:

```
[Webhook POST /api/tasks]
       │
       │  Body: { "Name": "...", "Status": "...", "Priority": 3 }
       ▼
[HTTP Request Node]
       │  POST to NocoDB: {NOCODB_URL}/api/v3/{baseId}/{tableId}
       │  Body: {{ $json.body }}
       ▼
[Respond to Webhook]
       │  Returns: { "success": true, "record": {...} }
```

---

## CORS Considerations

When your frontend (served by one webhook) calls another webhook endpoint,
you might encounter CORS (Cross-Origin Resource Sharing) issues.

### When CORS Is NOT an Issue

If both the HTML page and the API endpoints are on the **same n8n instance**
and use the **same domain**, CORS is not a problem:

```
Page:  https://my-n8n.cloud/webhook/dashboard     (same origin)
API:   https://my-n8n.cloud/webhook/api/tasks      (same origin) ✓
```

### When CORS IS an Issue

If your frontend is hosted elsewhere (e.g., GitHub Pages, Netlify) but
calls n8n webhooks, you need CORS headers:

```
Page:  https://my-site.netlify.app/dashboard       (different origin)
API:   https://my-n8n.cloud/webhook/api/tasks      (different origin) ✗
```

### Adding CORS Headers

In the Respond to Webhook node, add these response headers:

| Header | Value |
|--------|-------|
| `Access-Control-Allow-Origin` | `*` (or your specific domain) |
| `Access-Control-Allow-Methods` | `GET, POST, OPTIONS` |
| `Access-Control-Allow-Headers` | `Content-Type` |

**For production**, replace `*` with your specific domain:
```
Access-Control-Allow-Origin: https://my-site.netlify.app
```

### Handling Preflight Requests

Browsers send an OPTIONS request before POST requests. Create a separate
webhook to handle this:

```
[Webhook OPTIONS /api/tasks] ──▶ [Respond with CORS headers, empty body]
```

---

## Multiple Pages Pattern

You can serve an entire multi-page application from n8n by using different
webhook paths for each page.

### URL Structure

```
/webhook/dashboard          → Main dashboard page
/webhook/dashboard/tasks    → Tasks page
/webhook/dashboard/form     → Create task form
/webhook/api/tasks          → JSON API: list tasks
/webhook/api/tasks/create   → JSON API: create task
```

### Implementation

Create separate workflows (or one large workflow with multiple webhook
nodes) for each endpoint:

```
Workflow 1: "Dashboard Pages"
├── [Webhook GET /dashboard]        ──▶ [Respond: main page HTML]
├── [Webhook GET /dashboard/tasks]  ──▶ [Respond: tasks page HTML]
└── [Webhook GET /dashboard/form]   ──▶ [Respond: form page HTML]

Workflow 2: "Dashboard API"
├── [Webhook GET /api/tasks]        ──▶ [NocoDB query] ──▶ [Respond: JSON]
└── [Webhook POST /api/tasks]       ──▶ [NocoDB create] ──▶ [Respond: JSON]
```

### Navigation Between Pages

Use absolute links to navigate between pages:

```html
<nav>
  <a href="https://your-n8n.cloud/webhook/dashboard">Home</a>
  <a href="https://your-n8n.cloud/webhook/dashboard/tasks">Tasks</a>
  <a href="https://your-n8n.cloud/webhook/dashboard/form">New Task</a>
</nav>
```

---

## Security Best Practices

### 1. Never Embed Long-Lived Tokens in HTML

If your dashboard needs authentication, use short-lived session tokens:

```javascript
// WRONG — long-lived API token visible in page source:
const API_KEY = 'noco-abc123-permanent-key';

// CORRECT — short-lived token generated per session:
const SESSION_TOKEN = '{{ $json.sessionToken }}';  // expires in 1 hour
```

### 2. Validate All Input Server-Side

Never trust data from the frontend. Validate in n8n before writing to
NocoDB:

```javascript
// In an n8n Code node, before writing to NocoDB:
const name = $input.first().json.body.Name;
const priority = $input.first().json.body.Priority;

// Validate required fields
if (!name || name.trim().length === 0) {
  throw new Error('Name is required');
}

// Validate data types
if (priority < 1 || priority > 5) {
  throw new Error('Priority must be between 1 and 5');
}
```

### 3. Sanitize HTML Output

If displaying user-generated content, sanitize it to prevent XSS:

```javascript
// Simple sanitization function
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// Use when displaying user data:
cell.innerHTML = escapeHtml(record.Name);
```

### 4. Use HTTPS in Production

Always use HTTPS URLs for your n8n instance. Most n8n cloud instances
have HTTPS by default. For self-hosted, set up a reverse proxy with
SSL (e.g., nginx + Let's Encrypt).

### 5. Rate Limit Sensitive Endpoints

For endpoints that create or modify data, consider adding rate limiting
in your n8n workflow using a Code node or an external rate limiter.

### 6. Separate Read and Write Endpoints

Use different webhook paths for reading and writing:

```
GET  /webhook/api/tasks       → Read-only, less sensitive
POST /webhook/api/tasks       → Creates data, needs more protection
```

This makes it easier to add authentication to write endpoints only.
