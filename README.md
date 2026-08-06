# Flux

A quasi-autonomous development workflow built on Claude Code — a convention
and configuration layer over native primitives (hooks, skills, GitHub
Actions), not a new engine.

This repository is both the **plugin** ([plugins/flux/](plugins/flux/)) and
the **marketplace** that distributes it.

## Installation

In Claude Code:

```shell
/plugin marketplace add sbnet/flux
/plugin install flux@flux
```

Then, in the project you want flux to manage:

```shell
/flux-init
```

`flux-init` detects the stack, writes `flux-config.yml`, installs the CI
gate script and workflows, the `CLAUDE.md` contract and the specs index.
Requirements: `yq` v4, `gh` ≥ 2.20 authenticated, and a
`CLAUDE_CODE_OAUTH_TOKEN` repository secret for the automated review.

## How it works

Each flux-managed project carries a `flux-config.yml` at its root
([annotated reference](documentation/flux-config.example.yml)) declaring its
commands (lint, static analysis, tests, build) and which **gates** block
which event.

Two lines of defense:

1. **Local hooks** — the plugin runs
   [flux-gate.sh](plugins/flux/hooks/flux-gate.sh) on Claude Code events
   (`PostToolUse` after edits, `PreToolUse` on `git push`). A failing gate
   blocks the action and feeds the report back to the agent, which fixes it
   on its own.
2. **CI as source of truth** — the same script, same config, replayed by
   GitHub Actions (a copy is committed in each project for the runners),
   plus an automated PR review by `claude-code-action`. The review comments,
   it never approves: merging is a human decision.

## Skills

- **flux-init** — set up flux in a project.
- **spec-interview** — in-depth feature interview, written to
  `specs/SPEC-<ref>.md` with a status frontmatter and an index.
- **gh-issue** — actionable GitHub issues, linked to their spec.
- **gh-pr** — PRs written from the actual diff, with a CI watch-and-fix loop.
- **flux-feature** — the full cycle end to end; only merging stays human.
- **gh-address-comments** — review comments: human triage, autonomous fixes.

Together with the hooks they cover the full contribution cycle:
spec → issue → branch → gated push → PR → CI + automated review → human
triage → human merge.

## Status

Work in progress — see the
[scoping study](documentation/study-01-scoping.md) for the architecture,
decisions and phase plan. Current pilot: a Laravel/Vue/Inertia application.
