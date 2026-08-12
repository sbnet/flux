# A feature, end to end with flux

This walkthrough follows one real feature, a candidate CRUD in a
Laravel/Vue/Inertia app, through the whole flux cycle. Every command shown
was actually run on the pilot project.

It comes in two parts:

- **[Part 1](#part-1-the-normal-path)**: the normal path, one command.
  Read this one first, it is how you work day to day.
- **[Part 2](#part-2-the-manual-path)**: the same cycle driven skill by
  skill, for when you want to inspect a step before the next one, resume
  an interrupted cycle, or use a single piece in isolation.

Prerequisites: the flux plugin is installed and the project went through
`/flux:init`. See the [setup guide](setup.md) if that is not in place yet.

---

# Part 1: The normal path

Everything starts with one command:

```
/flux:feature candidate management (CRUD)
```

## What it decides

It calibrates the ceremony to the change, announces the choice in one
line, and proceeds. You can override that choice at any time.

| Path | For | Ceremony |
|---|---|---|
| **trivial** | typo, label, config tweak | no spec, no issue |
| **standard** | a small, well-described change | issue generated from your description, no interview |
| **full** | anything non-trivial or ambiguous | interview, then spec, then issue |

The candidate CRUD is a full-path feature.

## What it drives

1. The interview, then the spec file and the GitHub issue (full path).
2. Branch, implementation, tests. The gates run on every edit and on every
   push, so a style or test failure is fixed before it ever reaches GitHub.
3. Local verification: the `qa` subagent when the change has user flows,
   the `reviewer` subagent when it is large or risky.
4. The PR, written from the real diff, then CI watched and its failures
   fixed autonomously.
5. Once CI turns green: nothing fires on its own. The agent tells you the
   PR is ready and that a review is one command away
   (`/flux:review`, run locally); ask for it whenever you want one, and
   the triage happens right there, in the same session, once it lands.

## What you do

A few moments during the cycle:

- **Answer the interview** (full path only). Your answers become the
  acceptance criteria, which the QA agent, the reviewer and the PR review
  all check against later.
- **Ask for a review, when you want one.** Nothing reviews the PR on its
  own: `/flux:review` runs it, locally, in the session.
- **Triage the review**, once it lands. The agent presents each finding
  with its own assessment, you pick what to address, it fixes the
  retained items and brings CI back to green.

Then you merge. That is the last human action, and the only one the agent
never performs.

## What happens after the merge

No agent involved and nothing to do: the spec-lifecycle workflow flips the
linked spec to `status: implemented` and updates the index, and GitHub
deletes the merged branch.

If your session ends before the review lands, nothing is lost:
`/flux:gh-address-comments` picks the triage up later.

---

# Part 2: The manual path

The same nine steps, invoked one at a time. Everything below is what
Part 1 does for you.

## 1. Spec

```
/flux:spec-interview candidate management (CRUD)
```

The interview runs in rounds (data model, flows, edge cases, tradeoffs),
then writes `specs/SPEC-candidate-management.md` with a frontmatter
(`status: draft`) and updates the `specs/README.md` index.

You read it, correct it, and validate: the status becomes `validated`.
The acceptance criteria written here are what the reviewer, the QA agent
and the PR review will all check against later; the spec is the
contract for the whole cycle.

## 2. Issue

```
/flux:gh-issue
```

Creates the GitHub issue from the spec (context, goal, acceptance
criteria, spec reference), applies the project labels, and back-links the
issue number into the spec's frontmatter (`issue: "#2"`).

## 3. Branch and implementation

Work happens on `feat/candidate-management-crud`. While the agent edits,
the plugin's hooks run the gates from `flux-config.yml`:

- after each edit: `on_edit` gates (lint); a violation blocks the edit
  loop and feeds the report back to the agent, which fixes it;
- on `git push`: `on_push` gates (lint, static analysis, types, frontend
  lint/format, tests); a red gate blocks the push itself.

Nothing to invoke: this is the passive layer. Tests are written as part of
the implementation, not after.

## 4. QA: always worth it

The `qa` subagent starts the app for real and walks the spec's user flows
(create, search, soft-delete, restore…), probing unhappy paths: invalid
input, missing auth, double submission. Automated tests prove the units;
QA proves the feature. Nobody else in the cycle runs the app, so this
step never duplicates anything.

## 5. Local review: the judgment call

This is the one conditional step. The PR review (step 7) will
analyze the final diff anyway, so a local `reviewer` pass is an
**optimizer**, not a mandatory stage. Run it when a finding arriving
*after* the PR would be expensive to fix:

| Run `reviewer` when… | Skip it when… |
|---|---|
| the diff spans many files or layers | the change is small and contained |
| there is a schema or data migration | no persistent-state change |
| it touches auth, payments, permissions, file handling | low-risk surface |
| the spec has many acceptance criteria | one or two criteria |

The candidate CRUD hit three of the four left-column rows (32 files,
a migration, file uploads), so local review was worth it there. A one-file
label rename would not be.

Why not run it always? Because it costs a full review's worth of tokens
and largely overlaps the PR review. Why not never? Because on a large
diff, an architecture finding after the PR means a review round trip:
push → CI → re-review → re-triage, instead of a fix while the context is
still hot.

## 6. PR

```
/flux:gh-pr
```

Pushes (the `on_push` gates run one last time), then opens the PR: title
in conventional-commit form, body built from the actual diff (summary,
`Closes #2`, spec link, test plan, review notes). Then the skill watches
CI (`gh pr checks --watch`) and fixes failures autonomously, capped at
three attempts on the same error.

## 7. Review

There is no CI job to wait for: the review runs locally, in the session,
only when asked. Launch it once CI is green and a review is actually
wanted:

```
/flux:review
```

It reads the real diff and posts one summary comment on the PR (updated
in place on repeated runs) plus inline comments, covering logic,
architecture, security and spec conformance. It does not re-check what
the gates enforce. It never approves.

On the pilot feature it found two real issues the gates could not see: a
missing DB-level unique constraint the spec required, and an update path
that silently reset a field. Both came with inline comments.

## 8. Human triage

```
/flux:gh-address-comments
```

The agent lists each finding **with its own assessment** (it read the code,
it may disagree with the reviewer), you pick what to address in one
question, and it fixes the retained items autonomously (gates, push, CI
loop), then replies on each comment: addressed (with the commit) or
declined (with your triage reason).

This is the deliberate design choice of the cycle: **review comments are
never auto-addressed**. The automated reviewer proposes, the human
disposes, the agent executes.

## 9. Merge: the human step

CI green, review read, findings triaged. Merging is yours, the one action
the agent never performs. The rest of the ending is automated and
deterministic: the spec-lifecycle workflow flips the linked spec to
`status: implemented` and updates the index, and GitHub deletes the merged
branch (repository setting enabled by `/flux:init`).

---

## The cycle at a glance

| Step | Who decides | Who executes |
|---|---|---|
| Spec content | human (interviewed) | agent writes |
| Issue, branch, code, tests | agent | agent |
| QA | agent (always when flows exist) | agent |
| Local review | agent applies the rule above | agent |
| PR + CI fixes | agent | agent |
| Request a review | **human** | agent triggers it |
| Review triage | **human** | agent fixes |
| Merge | **human** | human |
| Post-merge lifecycle | nobody (deterministic) | repository workflows |
