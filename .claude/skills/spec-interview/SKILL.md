---
name: spec-interview
description: Interview the user about a feature they want to build, then write a complete spec to SPEC.md. Use when the user says "I want to build X" or asks for a spec/interview. Once the spec is complete, start a fresh session to execute it.
---

# Skill: Spec Interview

## Purpose

Interview the user in depth about something they want to build, then produce a complete specification written to `SPEC.md`.

## Instructions

When this skill is invoked, the user will typically pass a short description of what they want to build as `args`. If no description is provided, ask for one first.

### Phase 1 — Interview

Use `AskUserQuestion` to interview the user. Dig into the hard parts:

- **Technical implementation**: stack, data model, APIs, integrations, constraints
- **UI/UX**: flows, states, edge cases in the interface
- **Business rules**: what are the exact rules, who decides, what changes them
- **Edge cases**: what happens when X is missing, null, concurrent, or invalid
- **Tradeoffs**: performance vs. simplicity, flexibility vs. consistency, now vs. later
- **Concerns**: what worries the user most, what's uncertain, what could go wrong

Do **not** ask obvious questions (don't ask "what is the feature for?" if it was described). Go straight to the hard parts that the user might not have considered.

Keep asking until all ambiguity is resolved. Aim for 3–6 rounds of questions, grouping related questions per round (max 4 questions per `AskUserQuestion` call).

Stop interviewing when:
- Implementation could begin without further clarification
- Edge cases and tradeoffs are documented
- Acceptance criteria are clear

### Phase 2 — Write the spec

Write `SPEC.md` at the root of the project with the following structure:

```markdown
# Spec: [Feature Name]

## Overview

[2–3 sentences: what this is, why it matters, scope]

## Goals

- [Concrete, measurable goal]
- …

## Non-goals

- [Explicitly out of scope]
- …

## User flows

### [Flow name]

1. …
2. …

## Data model

[Tables / fields / relationships — only what's new or changed]

## API

### `METHOD /path`

- Auth: …
- Request: …
- Response: …
- Errors: …

## Business rules

- [Rule 1]
- …

## Edge cases

- [What happens when X]
- …

## UI / UX

[Key screens, states, error states, empty states]

## Technical decisions & tradeoffs

| Decision | Choice | Rationale |
|----------|--------|-----------|
| … | … | … |

## Open questions

- [ ] [Anything still unresolved]

## Acceptance criteria

- [ ] …
```

Omit sections that don't apply. Add sections if needed.

After writing, tell the user where the file is and what's left open (if anything).
