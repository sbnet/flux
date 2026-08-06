# Flux

A quasi-autonomous development workflow built on Claude Code — a convention
and configuration layer over native primitives (hooks, skills, GitHub
Actions), not a new engine.

This repository is both the **plugin** ([plugins/flux/](plugins/flux/)) and
the **marketplace** that distributes it.

## Installation

In a Claude Code session:

```shell
/plugin marketplace add sbnet/flux
/plugin install flux@flux
```

Or from the terminal — required with the VS Code extension, where the
`/plugin` command is not available:

```shell
claude plugin marketplace add sbnet/flux
claude plugin install flux@flux
```

Then, in the project you want flux to manage:

```shell
/flux:flux-init
```

To update to the latest version (session or terminal):

```shell
/plugin marketplace update flux        # or: claude plugin marketplace update flux
/reload-plugins                        # or restart the session
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

Full reference with usage, triggers and examples:
[documentation/skills.md](documentation/skills.md).

| Skill | One line |
|---|---|
| [flux-init](documentation/skills.md#flux-init) | set up flux in a project (config, gates, workflows, contract) |
| [spec-interview](documentation/skills.md#spec-interview) | in-depth interview → `specs/SPEC-<ref>.md` + index |
| [gh-issue](documentation/skills.md#gh-issue) | actionable GitHub issue, back-linked to its spec |
| [flux-feature](documentation/skills.md#flux-feature) | the full cycle end to end; only merging stays human |
| [gh-pr](documentation/skills.md#gh-pr) | PR from the actual diff + CI watch-and-fix loop |
| [gh-address-comments](documentation/skills.md#gh-address-comments) | review comments: human triage, autonomous fixes |
| [geo](documentation/skills.md#geo) | visibility in generative engines, complementary to SEO |
| [ui-review](documentation/skills.md#ui-review) | heuristic UI/UX review of the running app |

Two subagents complete the toolkit:
[reviewer](documentation/skills.md#reviewer) (conditional pre-PR review)
and [qa](documentation/skills.md#qa) (runs the app, walks the spec's
flows).

Together with the hooks they cover the full contribution cycle:
spec → issue → branch → gated push → PR → CI + automated review → human
triage → human merge.

**New to flux?** Read the
[step-by-step walkthrough](documentation/walkthrough.md) — one real
feature through the whole cycle, including when the local reviewer is
worth running and when it is not.

## License

[MIT](LICENSE) © Stéphane Brun. Any use, commercial included, requires
keeping the copyright notice — that is the attribution.

## Status

Work in progress — see the
[scoping study](documentation/study-01-scoping.md) for the architecture,
decisions and phase plan. Current pilot: a Laravel/Vue/Inertia application.
