---
name: gh-issue
description: Write and create a well-structured GitHub issue via the gh CLI, optionally from a SPEC-<ref>.md spec. Use when the user asks to create a GitHub issue/ticket.
---

# Skill: gh-issue

## Purpose

Create a clean, actionable GitHub issue, linked to its spec when one exists,
following the project conventions.

## Preparation

1. Read `flux-config.yml`: `github.labels` = default labels to apply.
2. Make sure those labels exist (`gh label list`); create missing ones
   (`gh label create <label> --color 5319e7 --description "managed by flux"`).
3. If the issue starts from a spec (`specs/SPEC-<ref>.md`), read it: the
   issue is its actionable summary, not a full copy.

## Writing

- **Title**: imperative, concise, no type prefix ("Add the candidate
  pipeline", not "feat: …" — commit conventions do not apply to issues).
- **Body**:

```markdown
## Context
[Why now, 1-3 sentences]

## Goal
[The expected, observable outcome]

## Acceptance criteria
- [ ] …

## References
- Spec: `specs/SPEC-<ref>.md` (if applicable)
```

- One issue = one deliverable. If the spec implies several independent work
  streams, offer to create several issues.

## Creation and links

1. `gh issue create --title "…" --body "…" --label <labels>` (add relevant
   labels on top of the defaults: bug, enhancement…).
2. If a spec is linked: record the number in its frontmatter (`issue: #N`)
   and in the spec's row in the `specs/README.md` index.
3. Give the issue URL to the user.
