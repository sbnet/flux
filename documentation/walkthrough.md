# A feature, end to end with flux

This walkthrough follows one real feature — a candidate CRUD in a
Laravel/Vue/Inertia app — through the whole flux cycle, step by step. Every
command shown was actually run on the pilot project. Use it as the reference
for how the pieces fit together, and for the one judgment call the cycle
contains (step 5).

Prerequisites: the flux plugin is installed, the project went through
`/flux-init`, and the `CLAUDE_CODE_OAUTH_TOKEN` secret is set on the repo.

---

## 1. Spec — `/flux:spec-interview`

```
/flux:spec-interview candidate management (CRUD)
```

The skill interviews you in rounds — data model, flows, edge cases,
tradeoffs — then writes `specs/SPEC-candidate-management.md` with a
frontmatter (`status: draft`) and updates the `specs/README.md` index.

You read it, correct it, and validate: the status becomes `validated`.
The acceptance criteria written here are what the reviewer, the QA agent
and the automated PR review will all check against later — the spec is the
contract for the whole cycle.

## 2. Issue — `/flux:gh-issue`

```
/flux:gh-issue
```

Creates the GitHub issue from the spec (context, goal, acceptance criteria,
spec reference), applies the project labels, and back-links the issue number
into the spec's frontmatter (`issue: "#2"`).

## 3. Branch and implementation

The agent works on `feat/candidate-management-crud`. While it edits, the
plugin's hooks run the gates from `flux-config.yml`:

- after each edit: `on_edit` gates (lint) — a violation blocks the edit
  loop and feeds the report back to the agent, which fixes it;
- on `git push`: `on_push` gates (lint, static analysis, types, frontend
  lint/format, tests) — a red gate blocks the push itself.

Nothing to invoke: this is the passive layer. Tests are written as part of
the implementation, not after.

## 4. QA — always worth it

The `qa` subagent starts the app for real and walks the spec's user flows
(create, search, soft-delete, restore…), probing unhappy paths — invalid
input, missing auth, double submission. Automated tests prove the units;
QA proves the feature. Nobody else in the cycle runs the app, so this
step never duplicates anything.

## 5. Local review — the judgment call

This is the one conditional step. The automated PR review (step 7) will
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
a migration, file uploads) — local review was worth it there. A one-file
label rename would not be.

Why not run it always? Because it costs a full review's worth of tokens
and largely overlaps the PR review. Why not never? Because on a large
diff, an architecture finding after the PR means a review round trip:
push → CI → re-review → re-triage, instead of a fix while the context is
still hot.

## 6. PR — `/flux:gh-pr`

```
/flux:gh-pr
```

Pushes (the `on_push` gates run one last time), then opens the PR: title in
conventional-commit form, body built from the actual diff — summary,
`Closes #2`, spec link, test plan, review notes. Then the skill watches CI
(`gh pr checks --watch`) and fixes failures autonomously, capped at three
attempts on the same error.

## 7. Automated review

The `claude-review` workflow posts one sticky comment on the PR: logic,
architecture, security, spec conformance — it does not re-check what the
gates enforce. It updates in place on every push. It never approves.

On the pilot feature it found two real issues the gates could not see: a
missing DB-level unique constraint the spec required, and an update path
that silently reset a field. Both came with inline comments.

## 8. Human triage — `/flux:gh-address-comments`

You read the review. Then:

```
/flux:gh-address-comments
```

The agent lists each finding **with its own assessment** (it read the code,
it may disagree with the reviewer), you pick what to address in one
question, and it fixes the retained items autonomously — gates, push, CI
loop — then replies on each comment: addressed (with the commit) or
declined (with your triage reason).

This is the deliberate design choice of the cycle: **review comments are
never auto-addressed**. The automated reviewer proposes, the human
disposes, the agent executes.

## 9. Merge — the human step

CI green, review read, findings triaged. Merging is yours — the one action
the agent never performs. After the merge, the spec's frontmatter moves to
`status: implemented`, the index is updated, and the branch is deleted.

---

## The cycle at a glance

| Step | Who decides | Who executes |
|---|---|---|
| Spec content | human (interviewed) | agent writes |
| Issue, branch, code, tests | agent | agent |
| QA | agent (always when flows exist) | agent |
| Local review | agent applies the rule above | agent |
| PR + CI fixes | agent | agent |
| Review triage | **human** | agent fixes |
| Merge | **human** | human |
