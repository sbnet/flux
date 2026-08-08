# Flux

A quasi-autonomous development workflow built on Claude Code: a convention
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

Or from the terminal (required with the VS Code extension, where the
`/plugin` command is not available):

```shell
claude plugin marketplace add sbnet/flux
claude plugin install flux@flux
```

Then, in the project you want flux to manage:

```shell
/flux:init
```

`/flux:init` detects the stack, writes `flux-config.yml`, installs the CI
gate script and workflows, the `CLAUDE.md` contract and the specs index.

To update to the latest version, refresh the marketplace, re-run the
install, then verify (session or terminal):

```shell
/plugin marketplace update flux        # or: claude plugin marketplace update flux
/plugin install flux@flux              # or: claude plugin install flux@flux
```

```shell
bash ~/.claude/plugins/marketplaces/flux/scripts/flux-doctor.sh
```

Refreshing the marketplace is necessary but not sufficient. Claude Code
pins each installed plugin to one version and runs that pinned copy; the
pin does not always follow the clone, and the install can report success
while changing nothing. The doctor is the one command that answers *am I
actually on the version I think I am*: it prints the marketplace version,
the pinned version and the installed skill names, exits 0 when they agree,
and repairs the pin with `--fix`. Restart the session after a repair: the
pin is read at startup, so `/reload-plugins` is not enough.

The command runs the copy inside the marketplace clone deliberately: that
clone does update reliably, so the script there is current even when the
installed plugin is stale, which is precisely the case you would be
diagnosing. This works around a Claude Code behavior. It does not change
how the plugin manager works.

Requirements: `yq` v4, `gh` 2.20 or later authenticated, and a
`CLAUDE_CODE_OAUTH_TOKEN` repository secret so the automated review can
run in CI. The [setup guide](documentation/setup.md) covers the secret
step by step, along with the API-key alternative, model selection and
troubleshooting.

## How it works

Each flux-managed project carries a `flux-config.yml` at its root
([annotated reference](documentation/flux-config.example.yml)) declaring its
commands (lint, static analysis, tests, build) and which **gates** block
which event.

Two lines of defense:

1. **Local hooks.** The plugin runs
   [flux-gate.sh](plugins/flux/hooks/flux-gate.sh) on Claude Code events
   (`PostToolUse` after edits, `PreToolUse` on `git push`). A failing gate
   blocks the action and feeds the report back to the agent, which fixes it
   on its own.
2. **CI as source of truth.** The same script and the same config are
   replayed by GitHub Actions (a copy is committed in each project for the
   runners), plus an automated PR review by `claude-code-action`. The
   review comments, it never approves: merging is a human decision.

## Skills

Full reference with usage, triggers and examples:
[documentation/skills.md](documentation/skills.md).

| Skill | One line |
|---|---|
| [init](documentation/skills.md#init) | set up flux in a project (config, gates, workflows, contract) |
| [spec-interview](documentation/skills.md#spec-interview) | in-depth interview → `specs/SPEC-<ref>.md` + index |
| [gh-issue](documentation/skills.md#gh-issue) | actionable GitHub issue, back-linked to its spec |
| [feature](documentation/skills.md#feature) | the single entry point: calibrates and drives the full cycle |
| [gh-pr](documentation/skills.md#gh-pr) | PR from the actual diff + CI watch-and-fix loop |
| [gh-address-comments](documentation/skills.md#gh-address-comments) | review comments: human triage, autonomous fixes |
| [geo](documentation/skills.md#geo) | visibility in generative engines, complementary to SEO |
| [ui-review](documentation/skills.md#ui-review) | heuristic UI/UX review of the running app |

Two subagents complete the toolkit:
[reviewer](documentation/skills.md#reviewer) (conditional pre-PR review)
and [qa](documentation/skills.md#qa) (runs the app, walks the spec's
flows).

Day to day, one command covers the whole contribution cycle:
`/flux:feature <what you want>` calibrates the ceremony to the change
(trivial, standard or full), then drives spec → issue → branch → gated
push → PR → CI + automated review → human triage, all in one session.
The two decisions that stay yours: the triage and the merge. Post-merge
housekeeping (spec status, branch deletion) is automated by the
repository.

**New to flux?** Read the
[walkthrough](documentation/walkthrough.md): one real feature through the
whole cycle, first in its one-command form, then step by step.

## License

[MIT](LICENSE) © Stéphane Brun. Any use, commercial included, requires
keeping the copyright notice. That notice is the attribution.

## Status

Work in progress. See the
[scoping study](documentation/study-01-scoping.md) for the architecture,
decisions and phase plan. Current pilot: a Laravel/Vue/Inertia application.
