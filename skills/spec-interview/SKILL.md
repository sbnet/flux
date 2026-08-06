---
name: spec-interview
description: Interview the user about a feature they want to build, then write a complete spec to specs/SPEC-<ref>.md (with an index). Use when the user says "I want to build X" or asks for a spec/interview. Once the spec is validated, chain into /gh-issue.
---

# Skill: Spec Interview

## Purpose

Interview the user in depth about what they want to build, then produce a
complete specification in the project's specs directory — **one spec per
file**, never a single overwritten `SPEC.md`.

## Location and naming

1. Read `flux-config.yml` at the project root: `specs.dir` gives the
   directory (default: `specs/`). Create it if missing.
2. Determine the `<ref>`:
   - if the spec starts from an existing GitHub issue → its number: `SPEC-42.md`;
   - otherwise → a short, stable kebab slug: `SPEC-candidate-pipeline.md`.
   The ref never changes once the file exists (even if an issue is opened
   later — it is then recorded in the frontmatter instead).
3. If a file already exists for this ref, update it rather than creating a
   second one.

## Phase 1 — Interview

Use `AskUserQuestion`. Dig into the hard parts:

- **Implementation**: stack, data model, APIs, integrations, constraints
- **UI/UX**: flows, states, edge cases in the interface
- **Business rules**: the exact rules, who decides, what changes them
- **Edge cases**: what happens when X is missing, null, concurrent, invalid
- **Tradeoffs**: performance vs simplicity, flexibility vs consistency, now vs later
- **Concerns**: what worries the user, what is uncertain

Do not ask obvious questions. Go straight to the points the user has probably
not considered. 3 to 6 rounds of questions, grouped by theme (max 4 questions
per call).

Stop when: implementation could start without further clarification, edge
cases and tradeoffs are documented, acceptance criteria are clear.

## Phase 2 — Write the spec

Write `<specs.dir>/SPEC-<ref>.md`:

```markdown
---
title: [Feature name]
ref: [ref]
status: draft        # draft | validated | implemented
issue:               # #N once the issue is created
date: [YYYY-MM-DD]
---

# Spec: [Feature name]

## Overview
[2-3 sentences: what, why, scope]

## Goals
- [Concrete, measurable goal]

## Non-goals
- [Explicitly out of scope]

## User flows
### [Flow name]
1. …

## Data model
[Tables / fields / relationships — only what is new or changed]

## API / Routes
[Method, path, auth, request, response, errors]

## Business rules
- …

## Edge cases
- [What happens when X]

## UI / UX
[Key screens, error states, empty states]

## Technical decisions & tradeoffs
| Decision | Choice | Rationale |

## Open questions
- [ ] …

## Acceptance criteria
- [ ] …
```

Omit sections that do not apply; add sections if needed.

## Phase 3 — Index and next step

1. Maintain `<specs.dir>/README.md`: a table
   `| Ref | Title | Status | Issue | File |` — add or update this spec's row.
2. Tell the user where the file is and what remains open.
3. When the user validates the spec: set `status: validated`, then offer to
   chain into `/gh-issue` to create the linked GitHub issue.
   `status: implemented` is set when the corresponding PR is merged.
