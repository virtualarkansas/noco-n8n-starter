# NocoDB as Your Dashboard — Button Columns, Webhooks & Views

You don't always need to build a custom HTML frontend. NocoDB itself can serve
as your user-facing dashboard. It provides grid, gallery, kanban, form, and
calendar views out of the box, with button columns that trigger n8n webhooks
for custom actions. This guide covers two approaches: using NocoDB natively
as your UI, and combining it with a custom frontend when you need more control.

---

## Approach A: NocoDB Native Dashboard (No Custom HTML)

In this approach, NocoDB **is** the dashboard. Users interact directly with
NocoDB's interface — viewing records in different layouts, filling out forms,
and clicking buttons that trigger n8n automations. No HTML, CSS, or JavaScript
needed.

### 1. NocoDB Views as Dashboard Pages

Every NocoDB table can have multiple views. Each view shows the same underlying
data in a different layout. Think of views as different "pages" of your
dashboard — a manager might use the kanban board while a data entry clerk uses
the form view, but they're working with the same table.

**Grid View** (default) — a spreadsheet-like table with sortable columns,
filters, and inline editing. Best for: data review, bulk editing, admin panels,
any situation where users need to see many records at once.

**Gallery View** — displays each record as a card with an optional cover image.
Best for: product catalogs, team directories, portfolio items, real estate
listings, or anything with a visual component. Configure which fields appear
on each card.

**Kanban View** — organizes records into columns based on a single-select or
status field. Drag records between columns to update their status. Best for:
project management, sales pipelines, content workflows, support ticket triage,
or any process with defined stages.

**Form View** — a clean data entry form generated from your table's fields.
Includes field descriptions, required field validation, and a customizable
submission message. Best for: surveys, intake forms, bug reports, contact
forms, event registration. You can hide fields that should be auto-filled
by automations.

**Calendar View** — shows records on a calendar based on a date field. Best
for: event scheduling, content calendars, deadline tracking, booking systems,
or any date-oriented data.

#### Shared Views

Any view can be shared via a public link. Go to the view's toolbar → click
**Share** → toggle **Enable shared view**. This generates a URL anyone can
access without a NocoDB account.

Shared views are read-only by default (except form views, which accept
submissions). They respect the view's filters, sorts, and hidden fields — so
you can create a filtered view showing only "Published" records and share that
link publicly while keeping draft records private.

Use shared views when you want to give external users access to specific data
without building a custom frontend.

### 2. Button Columns → n8n Webhooks

Button columns add clickable buttons to each row in your table. When a user
clicks a button, it triggers an action — opening a URL, running a webhook,
or executing a script. This is how you connect NocoDB's UI to n8n automations
without writing any frontend code.

#### How Button Columns Work

Add a button column to your table like any other field. Configure it with:
- **Label**: The text shown on the button (e.g., "Approve", "Send Email")
- **Action type**: What happens when clicked

The three action types are:
- **Open URL** — navigates to a URL (can include record field values)
- **Run Webhook** — triggers a NocoDB webhook configured on the table
- **Run Script** — executes a custom script (advanced)

#### Setting Up a Button → n8n Webhook

The **Run Webhook** action requires a webhook to already exist on the table.
Here's the setup process:

1. **Create a webhook on the table first.** Go to the table's toolbar →
   **Details** → **Webhooks** → **Create Webhook**. Set the event type (you
   can use "After Update" or "Manual Trigger") and point the URL to your n8n
   webhook endpoint (e.g., `https://your-n8n.app.n8n.cloud/webhook/approve-record`).

2. **Add a button column.** Create a new field → type "Button" → action type
   "Run Webhook" → select the webhook you created in step 1.

3. **Build the n8n workflow.** Create a workflow with a Webhook node that
   listens on the path you configured. The webhook payload includes the
   record data, so your workflow can process it accordingly.

The same webhook can be reused across multiple button columns if they should
trigger the same action.

**Important limitation:** Button columns are **not** available in shared views
or shared bases. They only work for logged-in NocoDB users with access to the
base. If you need external users to trigger actions, use a form view that
submits to an n8n webhook, or build a custom frontend.

#### Button Column Examples

**"Approve" button** — A project management table has a Status field. The
Approve button triggers an n8n workflow that:
1. Updates the record's Status to "Approved"
2. Sends a Slack notification to the team
3. Creates a task in an external project management tool

**"Generate Report" button** — A sales table tracks deals. The Generate Report
button triggers an n8n workflow that:
1. Reads the record's data from NocoDB
2. Generates a PDF report using a template
3. Uploads the PDF to Google Drive
4. Updates the record with a link to the report

**"Sync to CRM" button** — A contacts table. The Sync button triggers an n8n
workflow that:
1. Reads the contact record
2. Checks if the contact exists in the CRM (HubSpot, Salesforce, etc.)
3. Creates or updates the CRM record
4. Writes the CRM ID back to the NocoDB record

### 3. NocoDB Record Webhooks (Automatic Triggers)

While button columns require a user click, record webhooks fire automatically
when data changes. These are the backbone of event-driven automations — when
a record is created, updated, or deleted, NocoDB sends a POST request to the
URL you configure.

#### Available Webhook Events

| Event | Fires When |
|-------|-----------|
| After Insert | A new record is created |
| After Update | An existing record is modified |
| After Delete | A record is deleted |
| After Bulk Insert | Multiple records are created at once |
| After Bulk Update | Multiple records are updated at once |
| After Bulk Delete | Multiple records are deleted at once |

#### Setting Up Record Webhooks

Go to your table's toolbar → **Details** → **Webhooks** → **Create Webhook**.

Configure:
- **Event**: Which data change triggers the webhook
- **Method**: POST (default)
- **URL**: Your n8n webhook endpoint
- **Headers**: Optional (e.g., for authentication)

#### Conditional Webhooks

You can add conditions to webhooks so they only fire when specific criteria
are met. The condition evaluates the **transition** — it fires when the
condition goes from not-met to met, not on every update.

For example, if you set a condition `Status eq "Complete"`:
- Record created with Status = "Draft" → webhook does NOT fire
- Status updated from "Draft" to "In Progress" → webhook does NOT fire
- Status updated from "In Progress" to "Complete" → webhook FIRES
- Record updated while Status stays "Complete" → webhook does NOT fire

This is powerful for building workflows that react to specific state changes
without processing every update.

#### Webhook Payload

The POST request includes a JSON payload with the full event data:

```json
{
  "type": "records.after.update",
  "id": "unique-event-id",
  "data": {
    "table_id": "tbl_abc123",
    "table_name": "Tasks",
    "view_id": "vw_xyz789",
    "previous_rows": [{ "Id": 1, "Status": "In Progress", "Title": "Fix bug" }],
    "rows": [{ "Id": 1, "Status": "Complete", "Title": "Fix bug" }]
  }
}
```

The payload includes both the previous and current state of the record, so
your n8n workflow can compare values and act on the specific changes.

**Custom payloads:** On enterprise plans, you can customize the webhook payload
using Handlebars syntax. On free/team plans, you get the standard payload
format shown above.

#### Where Webhooks Can Send

Webhooks send to any URL that accepts POST requests:
- **n8n webhook endpoints** (most common in this template)
- Slack incoming webhooks (for notifications)
- Discord webhooks
- Zapier/Make/other automation platforms
- Your own custom API endpoints

### 4. Pattern: NocoDB + n8n (No Frontend)

This is the simplest architecture — NocoDB handles all user interaction and
n8n handles all automation. No HTML to write, no CSS to style, no JavaScript
to debug.

```
┌─────────────────────────┐         ┌──────────────────────────┐
│        NocoDB            │         │          n8n             │
│                          │         │                          │
│  Grid/Kanban/Form views  │────────▶│  Webhook nodes receive   │
│  (user interacts here)   │  button │  button clicks & record  │
│                          │  click  │  change events           │
│  Record webhooks fire    │────────▶│                          │
│  on insert/update/delete │  event  │  Workflows process data, │
│                          │         │  call external APIs,     │
│  Data updated by n8n     │◀────────│  update NocoDB records   │
│  (via REST API)          │  API    │                          │
└─────────────────────────┘         └──────────────────────────┘
```

**When to use this pattern:**
- Your users are comfortable with NocoDB's interface
- You need data entry, status tracking, or approval workflows
- You want to automate actions based on data changes
- You don't need a branded or custom-designed interface
- You want the fastest path from idea to working system

**When to use a custom frontend instead:**
- You need a public-facing interface (shared views are limited)
- You need complex interactions NocoDB doesn't support natively
- You need a branded experience with custom design
- You need client-side logic (calculations, validation, animations)

### 5. Step-by-Step: Build a Task Tracker with NocoDB + n8n

Here's a complete example of building a task management system with no custom
frontend.

**Step 1: Create the table in NocoDB**

Create a "Tasks" table with these fields:
- Title (Single Line Text)
- Description (Long Text)
- Status (Single Select: "To Do", "In Progress", "Done")
- Priority (Single Select: "Low", "Medium", "High")
- Assignee (Single Line Text or Email)
- Due Date (Date)
- Created (Created Time — auto-filled)

**Step 2: Create views**

- **Kanban view** ("Board"): Group by Status. This is your main dashboard —
  drag tasks between columns to update their status.
- **Form view** ("Submit Task"): Hide the Status field (default to "To Do"),
  hide Created. Share this form's link for task submissions.
- **Calendar view** ("Schedule"): Use Due Date as the date field. See all
  tasks on a calendar.
- **Grid view** ("All Tasks"): Default view filtered by Assignee for personal
  task lists.

**Step 3: Set up webhooks**

Create two webhooks on the Tasks table:

1. **New Task Notification**: Event = After Insert. URL = your n8n webhook
   endpoint (e.g., `/webhook/new-task`). This fires every time someone submits
   the form.

2. **Task Completed**: Event = After Update. Condition: Status eq "Done".
   URL = `/webhook/task-done`. This fires only when a task moves to "Done".

**Step 4: Build n8n workflows**

*New Task workflow:*
- Webhook node (receives new task data)
- HTTP Request node (sends Slack message: "New task: {title} assigned to
  {assignee}")

*Task Completed workflow:*
- Webhook node (receives completed task data)
- HTTP Request node (sends Slack message: "Task completed: {title}")
- HTTP Request node (updates a "Completed Count" record in a Stats table)

**Step 5: Add button columns (optional)**

- "Start" button: Triggers a webhook that sets Status to "In Progress" and
  logs the start time.
- "Archive" button: Triggers a webhook that moves the record to an Archive
  table and deletes it from Tasks.

The entire system works without writing a single line of HTML.

### When to Use NocoDB Native (Approach A)

- You want a working dashboard in minutes, not hours
- Your users are comfortable with a spreadsheet-like interface
- You need CRUD operations without writing any HTML/JS
- You want kanban boards, calendars, or galleries out of the box
- You're building internal tools, not public-facing websites

---

## Approach B: Custom Frontend via n8n Webhooks

For the full guide on building custom HTML frontends served by n8n webhooks,
see [docs/n8n-webhook-frontend.md](n8n-webhook-frontend.md).

Use a custom frontend when you need: public-facing pages, custom branding,
complex UI interactions, single-page app behavior, or interfaces that go
beyond what NocoDB views offer.

### Combining Custom Frontend + NocoDB Views

Sometimes you want the best of both worlds: a custom HTML dashboard for
external users and NocoDB views for internal administration. In this pattern,
NocoDB serves as both the database and the admin panel.

### Architecture

```
External Users                    Internal Team
     │                                  │
     ▼                                  ▼
┌──────────────┐              ┌─────────────────┐
│ Custom HTML  │              │  NocoDB Views    │
│ (via n8n     │              │  (Grid, Kanban,  │
│  webhooks)   │              │   Form, etc.)    │
└──────┬───────┘              └────────┬────────┘
       │                               │
       │  fetch() → n8n webhooks       │  Button clicks / webhooks
       │                               │
       ▼                               ▼
┌──────────────────────────────────────────────┐
│                    n8n                        │
│  (workflow engine — handles both interfaces)  │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │     NocoDB      │
              │   (database)    │
              └─────────────────┘
```

**Use this when:**
- External users need a polished, branded interface
- Internal team needs quick access to all data for management
- You want NocoDB's admin features (bulk edit, import/export, audit log)
  without rebuilding them in your frontend

### Combining Both

The key insight is that both interfaces share the same NocoDB database and n8n
workflows. A record created through the custom frontend appears immediately in
NocoDB's grid view. A status change made by an admin in NocoDB's kanban view
triggers the same webhooks as a status change from the frontend.

This means you can:
- Build a simple public-facing form as HTML served by n8n
- Manage submissions in NocoDB's grid view
- Use kanban view for workflow stages
- Add button columns for admin actions (approve, reject, escalate)
- Let webhooks keep everything in sync

---

## Comparison: NocoDB Native vs Custom Frontend

| Aspect | NocoDB Native | Custom Frontend |
|--------|--------------|----------------|
| Setup time | Minutes | Hours |
| Custom branding | Limited | Full control |
| CRUD operations | Built-in | Must build |
| Public sharing | Shared views | n8n webhooks |
| Button actions | Button columns | JavaScript |
| Kanban/Calendar | Built-in views | Must build |
| Complex UI logic | Limited | Full control |
| User authentication | NocoDB roles | Must build |
| Mobile responsive | Built-in | Must build |

## Quick Reference: When to Use What

| Scenario | Recommended Approach |
|----------|---------------------|
| Internal tool for your team | NocoDB views only (Approach A) |
| Simple data entry for external users | NocoDB shared form view |
| Read-only data display for external users | NocoDB shared grid/gallery view |
| Branded public-facing dashboard | Custom HTML frontend (Approach B) |
| Admin panel + public interface | Both (Approach B) |
| Approval/review workflows | NocoDB kanban + button columns |
| Event-driven automations | NocoDB record webhooks → n8n |
| Scheduled data processing | n8n Schedule Trigger → NocoDB API |

---

## Common Pitfalls

**Button columns don't work in shared views.** If you share a view publicly,
users won't see button columns. Use form views or custom frontends for external
user interactions.

**Webhook conditions evaluate transitions, not current state.** A condition
like `Status eq "Complete"` only fires when the status *changes to* "Complete",
not on every update while it is already "Complete". This is usually what you
want, but it's important to understand.

**Webhooks don't retry on failure.** If your n8n endpoint is down when a
webhook fires, the event is lost. For critical workflows, consider having n8n
poll NocoDB periodically as a backup, or use NocoDB's audit log to detect
missed events.

**Rate limits apply to API calls.** NocoDB has a rate limit of 5 requests per
second per user. If your n8n workflow makes many NocoDB API calls in rapid
succession, add small delays between requests or batch operations where
possible.

**Shared view links don't update when you rename the view.** The share link
is permanent once generated. Renaming or reconfiguring the view doesn't break
existing links.
