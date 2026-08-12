# Flux

A quasi-autonomous development workflow built on Claude Code: a convention
and configuration layer over native primitives (hooks, skills, GitHub
Actions), not a new engine.

This repository is both the **plugin** ([plugins/flux/](plugins/flux/)) and
the **marketplace** that distributes it.

## Installation

Installing flux writes two separate things, and telling them apart explains
almost every update problem:

- the **marketplace**, a git clone of this repository under
  `~/.claude/plugins/marketplaces/flux`, shared by every Claude Code on the
  machine;
- the **install pin**, a line in `~/.claude/plugins/installed_plugins.json`
  naming the version your sessions actually run, out of
  `~/.claude/plugins/cache/flux/flux/<version>`.

Refreshing the first does not always move the second. That gap is why
[flux-doctor.sh](scripts/flux-doctor.sh) exists.

Neither of those two is a project's copy of `flux-config.yml`, the GitHub
workflows, or `flux-gate.sh`: `/flux:init` writes those once, into each
project. The doctor cannot see them, and updating the plugin does not
touch them either. After an update, re-run `/flux:init` in every project
that was set up before it; see [setup guide: staying in
sync](documentation/setup.md#staying-in-sync).

### Install from the surface you work in

A machine usually carries more than one Claude Code binary. They share the
marketplace clone and the plugin cache, but they do not record the pin the
same way: some builds store one object per plugin, others a list of entries
carrying a `scope`. An install typed in the terminal can therefore write a
pin the VS Code session never reads, print `Successfully installed`, and
leave that session on the old version.

| Surface | Which binary | Where to install from |
|---|---|---|
| Terminal | whatever `which claude` points at | `claude plugin …` |
| VS Code extension | its own bundled binary, inside the extension directory | the command palette, or `/plugin` in a session |

So: install and update from the surface you actually use, then verify with
the doctor below.

**In a session**, whichever surface hosts it:

```shell
/plugin marketplace add sbnet/flux
/plugin install flux@flux
```

**From VS Code**, if `/plugin` is unavailable in your build: command palette
(`Ctrl+Shift+P`, `Cmd+Shift+P` on macOS), then **Claude Code: Install
Plugin**.

**From the terminal**:

```shell
claude plugin marketplace add sbnet/flux
claude plugin install flux@flux
```

Restart the session in every case. The pin is read at startup, so
`/reload-plugins` is not enough to pick up a new install.

Then, in the project you want flux to manage:

```shell
/flux:init
```

`/flux:init` detects the stack, writes `flux-config.yml`, installs the CI
gate script and workflows, the `CLAUDE.md` contract and the specs index.

### Updating

Recent builds update a plugin in one command:

```shell
claude plugin update flux@flux
```

Older ones have no `plugin update`. Refresh the marketplace and re-run the
install instead, which is also the sequence the `/plugin` commands follow in
a session:

```shell
claude plugin marketplace update flux
claude plugin install flux@flux
```

Either way, restart the session, then verify. `claude plugin list` is not
that verification: it answers for the binary you typed it into, which is
not necessarily the one running your sessions.

### Checking what you actually run

```shell
bash ~/.claude/plugins/marketplaces/flux/scripts/flux-doctor.sh
```

The doctor answers one question: *am I on the version I think I am?* It
prints the marketplace version, the pinned version and the shape it was
stored in, the install path and whether it exists, and whether the installed
skill names still match the marketplace. It exits 0 when they agree, 1 when
they drift, 2 when it cannot tell, so it also works as a check in a script.

Add `--fix` to repair: it copies the marketplace plugin into the versioned
cache path and rewrites the pin in place, keeping the shape your build
wrote. It backs up `installed_plugins.json` first and prints the command to
restore it, and it is idempotent, so a second run reports agreement and
changes nothing. Restart the session afterwards.

Run it from the marketplace clone, as written above, rather than from the
installed copy: the clone updates reliably, so the script there is current
even when the install is stale, which is exactly the situation you would be
diagnosing.

Worth being clear about what this is. Stale pins are a Claude Code
behavior; the doctor observes and repairs the state they leave behind, and
changes nothing about how the plugin manager works. The
[setup guide](documentation/setup.md#troubleshooting) covers the symptom it
is easiest to misread: after a release that renames a skill, a stale pin
surfaces as `Unknown command: /flux:<name>` rather than as a version
problem.

### Requirements

`yq` v4 and `gh` 2.20 or later, authenticated. The
[setup guide](documentation/setup.md) covers both and their common
install traps.

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
   runners). The PR review itself is not a CI job: it runs locally, on
   demand (`/flux:review`). It comments, it never approves: merging is a
   human decision.

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
| [review](documentation/skills.md#review) | run the PR review locally, on demand |
| [gh-address-comments](documentation/skills.md#gh-address-comments) | review comments: human triage, autonomous fixes |
| [geo](documentation/skills.md#geo) | visibility in generative engines, complementary to SEO |
| [ui-review](documentation/skills.md#ui-review) | heuristic UI/UX review of the running app |

Four subagents complete the toolkit:
[reviewer](documentation/skills.md#reviewer) (conditional pre-PR review),
[qa](documentation/skills.md#qa) (runs the app, walks the spec's flows,
quick by default, deep on request), and
[pr-review](documentation/skills.md#pr-review) /
[comment-triage](documentation/skills.md#comment-triage), which do the
heavy reading behind `review` and `gh-address-comments`.

Day to day, one command covers the whole contribution cycle:
`/flux:feature <what you want>` calibrates the ceremony to the change
(trivial, standard or full), then drives spec → issue → branch → gated
push → PR → CI, then tells you how to ask for a review (`/flux:review`,
run locally) and runs its human triage, all in one session. The decisions
that stay yours: whether/when to request the review, its triage, and the
merge. Post-merge housekeeping (spec status, branch deletion) is
automated by the repository.

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
