---
title: Duke mode
ref: duke-mode
status: validated
issue: "#8"
date: 2026-09-30
---

# Spec: Duke mode

## Overview

A `/flux:duke` skill that chains full delivery cycles over the GitHub
backlog without stopping: pick the next issue, build it, open the PR,
get CI green, review it, triage and fix the findings, merge, move on. It
is the only place in flux where the agent merges and triages on its own,
so entry is guarded: the backlog must be fully written as issues, nothing
may be in flight, and the user must ask explicitly and type a
confirmation phrase.

## Goals

- Run several issues end to end in one session with no human step
  between them.
- Keep the "never merge" rule intact everywhere else: the exception only
  exists inside an explicitly confirmed duke session.
- Stop at the first sign of trouble rather than pile work on a doubtful
  base.

## Non-goals

- Writing issues or specs: duke consumes the backlog, it never runs an
  interview. `feature`, `spec-interview` and `gh-issue` stay the way to
  fill it.
- Parallel work on several issues.
- A technical guard (hook) against `gh pr merge`: the rule stays a
  convention, as it is today.
- Persisting the mode across sessions.

## User flows

### Entering duke mode

1. The user runs `/flux:duke` (optionally `/flux:duke <max>` to override
   the issue cap). Duke is never entered implicitly, including from a
   request that merely sounds like "do everything".
2. Duke checks the entry preconditions (see business rules). If any
   fails, it refuses entry, lists every offending item and what is
   missing, and stops. Nothing is modified.
3. Duke shows the plan: the eligible issues in processing order, capped
   at `max_issues`, the merge method, the sensitive paths that will halt
   it, and a reminder that it will merge and triage without asking.
4. Duke asks the user to type exactly `I am the duke`. Any other answer,
   including "yes", cancels.

### The loop, per issue

1. Update the default branch, branch `feat/<N>-<slug>` from it.
2. Implement with tests (feature skill step 2); gates run as usual.
3. Local verification: `qa` subagent when there are observable flows,
   `reviewer` subagent per the usual risk rule.
4. Commit, push, open the PR (gh-pr conventions, `Closes #N`).
5. Watch CI, fix failures (3 attempts on the same error).
6. Run the review flow (`pr-review` subagent, findings posted as
   comments).
7. Auto triage: run the `comment-triage` subagent, fix every finding it
   assesses as valid, reply on each comment with the outcome (fixed, or
   dismissed with the reason), bring CI back to green.
8. Check the merge guard (see business rules). If it passes, merge with
   `duke.merge_method`, delete the branch, confirm the issue is closed.
   If it fails, stop.
9. Next issue, until an exit condition is reached.

### Exit

Duke leaves the mode on any of: backlog empty, cap reached, user
interruption, a stop condition, end of session. It always ends with a
report: merged PRs, closed issues, findings fixed and dismissed per PR,
and, on a stop, the blocking reason and the PR left open.

## Configuration

New optional section in `flux-config.yml`, defaults used when absent:

```yaml
duke:
  max_issues: 5              # per session; /flux:duke <n> overrides
  merge_method: squash       # squash | merge | rebase
  sensitive_paths:           # a PR touching any of these is never auto-merged
    - "database/migrations/**"
    - "**/auth/**"
    - "**/*payment*"
```

## Business rules

- **Entry preconditions**, all required:
  - Every open issue labelled with `github.labels` has an
    "Acceptance criteria" section with at least one checkbox.
  - Every such issue that is non-trivial links a spec
    (`specs/SPEC-<ref>.md`) that exists and is `validated`.
  - No open PR exists in the repository from a flux branch
    (`feat/*`, `fix/*`), and no such issue is assigned or labelled as in
    progress.
  - The working tree is clean and the default branch is up to date with
    its remote.
  - At least one eligible issue exists.
- **Eligible issues**: open, carrying the flux label, processed in
  ascending number order; an issue that says `Depends on #M` with #M
  still open is deferred until #M is merged in this session, and if #M
  is not in the plan, the dependent issue is excluded from the plan and
  listed as such.
- **Confirmation**: exact string `I am the duke`, typed by the user in
  answer to the plan. Case and spacing must match.
- **Merge guard**, all required before merging:
  - all CI checks green on the PR's head commit;
  - no `blocking` finding (pr-review severity) left unfixed after the auto triage;
  - every acceptance criterion of the issue (and spec) verified, and
    ticked in the PR body test plan;
  - no changed file matches `duke.sensitive_paths`, and the diff does not
    otherwise touch a schema migration, authentication, authorization,
    payments or data deletion (judgment on top of the path list).
- **Stop, never skip**: any failed guard, 3 failed attempts on the same
  error, a merge conflict, or a scope ambiguity ends duke mode for the
  whole session. The current PR stays open for the human, with a comment
  explaining why duke stopped.
- **Interruption**: when the user says stop, duke finishes the current
  atomic step (a commit, a push, a reply), does not start the next one,
  and reports.
- **No persistence**: the mode lives only in the conversation. A new
  session, or a relaunch after a stop, needs a new `/flux:duke` and a new
  confirmation.
- Gates are never bypassed, in duke mode as elsewhere.

## Edge cases

- Backlog empty at entry: refuse entry ("nothing to do"), no
  confirmation asked.
- The cap is smaller than the eligible list: the plan shows the first
  `max_issues` and the count left for a later run.
- A new flux issue appears mid-session: it is not picked up; the plan is
  fixed at confirmation.
- Branch protection requires an approving review: `gh pr merge` fails,
  duke stops and reports (it never approves its own PR, never uses
  `--admin`).
- CI has no checks configured: the "CI green" guard cannot be met, duke
  refuses entry.
- The auto triage dismisses every finding: allowed, provided each
  dismissal is replied to with a reason and none is `blocking`.

## Technical decisions & tradeoffs

| Decision | Choice | Rationale |
|---|---|---|
| Who merges | Duke itself | Chaining dependent issues needs the previous work on the default branch; stacked PRs complicate everything downstream. |
| Failure policy | Stop the whole session | Skipping would keep building on a base the human has not seen. |
| Triage | Automatic | Duke's value is running unattended; the replies on each comment keep the decisions auditable. |
| Guard | Convention only | Consistent with today: no hook enforces "never merge" outside duke either. |
| Settings | `duke:` config section | Merge method and sensitive paths are project-specific. |
| Confirmation | Typed phrase | A reflexive "yes" is not consent to unattended merges. |
| Invocation | `disable-model-invocation: true` | Only the user can start the skill; Claude cannot slide into it from a vague request. |

## Changes to existing contracts

- `templates/CLAUDE.md` and the `feature` skill's "Never" section: merging
  and untriaged fixes are forbidden except inside a confirmed duke
  session.
- Minor version bump (new skill, new config key).

## Acceptance criteria

- [ ] `plugins/flux/skills/duke/SKILL.md` exists and implements the
      entry checks, plan, typed confirmation, loop, merge guard, stop and
      exit report described above.
- [ ] `/flux:duke` refuses entry, listing each offending item, when any
      precondition fails, and never asks for confirmation in that case.
- [ ] Any answer other than exactly `I am the duke` cancels.
- [ ] The `duke:` section is documented in the config template and the
      annotated reference, with defaults.
- [ ] `templates/CLAUDE.md` and the `feature` skill carve out the duke
      exception without weakening the rule elsewhere.
- [ ] `documentation/skills.md` and the README skill table describe duke.
- [ ] Version bumped to 0.11.0 in `plugin.json` and `marketplace.json`.
