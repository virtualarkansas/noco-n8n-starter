---
name: teach-impeccable
description: One-time setup that gathers design context for your project and saves it to CLAUDE.md. Run once to establish persistent design guidelines for your dashboards and frontends.
---

Gather design context for this project, then persist it for all future sessions.

## Step 1: Explore the Codebase

Before asking questions, thoroughly scan the project to discover what you can:

- **CLAUDE.md**: Project purpose, target audience, existing conventions
- **frontend/templates/**: Current HTML templates and their design patterns
- **frontend/styles/main.css**: Existing CSS custom properties, colors, spacing
- **Package.json / config files**: Tech stack, dependencies
- **Any existing dashboards or pages**: Current design patterns, typography, colors in use

Note what you've learned and what remains unclear.

## Step 2: Ask UX-Focused Questions

STOP and call the AskUserQuestionTool to clarify. Focus only on what you couldn't infer from the codebase:

### Users & Purpose
- Who uses this dashboard? What's their context when using it?
- What job are they trying to get done?
- What emotions should the interface evoke? (confidence, delight, calm, urgency, etc.)

### Brand & Personality
- How would you describe the brand personality in 3 words?
- Any reference sites or apps that capture the right feel? What specifically about them?
- What should this explicitly NOT look like? Any anti-references?

### Aesthetic Preferences
- Any strong preferences for visual direction? (minimal, bold, elegant, playful, technical, organic, etc.)
- Light mode, dark mode, or both?
- Any colors that must be used or avoided?

### Dashboard-Specific
- What kind of data will the dashboards display? (inventory, contacts, tasks, etc.)
- How many records typically? (affects table vs card decisions)
- Who will see these dashboards? (internal team only, or shared externally?)

### Accessibility & Inclusion
- Specific accessibility requirements? (WCAG level, known user needs)
- Considerations for reduced motion, color blindness, or other accommodations?

Skip questions where the answer is already clear from the codebase exploration.

## Step 3: Write Design Context

Synthesize your findings and the user's answers into a `## Design Context` section:

```markdown
## Design Context

### Users
[Who they are, their context, the job to be done]

### Brand Personality
[Voice, tone, 3-word personality, emotional goals]

### Aesthetic Direction
[Visual tone, references, anti-references, theme preference]

### Dashboard Design Principles
[3-5 principles derived from the conversation that should guide all dashboard and frontend design decisions]

### Color Palette
[Primary, semantic, and neutral colors — defined as CSS custom properties]

### Typography
[Chosen fonts with Google Fonts CDN links, type scale]
```

Write this section to CLAUDE.md in the project root. If the file exists, append or update the Design Context section.

Confirm completion and summarize the key design principles that will now guide all future work.
