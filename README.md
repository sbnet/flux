# Flux

A quasi-autonomous development workflow built on Claude Code — a convention
and configuration layer over native primitives (hooks, skills, GitHub
Actions), not a new engine.

## How it works

Each flux-managed project carries a `flux-config.yml` at its root
([annotated reference](documentation/flux-config.example.yml)) declaring its
commands (lint, static analysis, tests, build) and which **gates** block
which event.

Two lines of defense:

1. **Local hooks** — [`hooks/flux-gate.sh`](hooks/flux-gate.sh) runs the
   configured gates on Claude Code events (`PostToolUse` after edits,
   `PreToolUse` on `git push`). A failing gate blocks the action and feeds
   the report back to the agent, which fixes it on its own.
2. **CI as source of truth** — the same script, same config, replayed by
   GitHub Actions ([templates/](templates/)), plus an automated PR review
   by `claude-code-action`. The review comments, it never approves: merging
   is a human decision.

## Skills

Canonical versions live in [`skills/`](skills/) and are installed into each
project's `.claude/skills/`:

- **spec-interview** — in-depth feature interview, written to
  `specs/SPEC-<ref>.md` with a status frontmatter and an index.
- **gh-issue** — actionable GitHub issues, linked to their spec.
- **gh-pr** — PRs written from the actual diff, linked to issue and spec.

Together with the hooks they cover the full contribution cycle:
spec → issue → branch → gated push → PR → CI + automated review → human merge.

## Status

Work in progress — see the
[scoping study](documentation/study-01-scoping.md) for the architecture,
decisions and phase plan. Current pilot: a Laravel/Vue/Inertia application.
