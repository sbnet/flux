---
name: gh-pr
description: Write and open the pull request for the current branch via the gh CLI, linked to its issue and spec. Use when the user asks to create/open/write a PR.
---

# Skill: gh-pr

## Purpose

Open a well-written PR for the current branch: a faithful summary of the
changes, links to the issue and spec, and a verifiable test plan.

## Preconditions (check, fix if needed)

1. Current branch ≠ default branch. Otherwise, offer to create one
   (`feat/<ref>-<slug>` or `fix/<slug>`).
2. Everything is committed and pushed (`git status`,
   `git push -u origin HEAD`). The flux-gate hook runs the gates on push:
   if it blocks, fix the failures first, never bypass it.
3. Read `flux-config.yml`: `github.labels` = default PR labels.

## Writing

- **Title**: conventional commit format (`feat(candidates): add pipeline
  board`); it often becomes the squash-merge commit message.
- **Body**: build it from the actual diff (`git diff main...HEAD`), not
  from memory:

```markdown
## Summary
[What the PR does and why, 2-4 sentences]

Closes #N            <!-- if an issue is linked; otherwise omit -->
Spec: `specs/SPEC-<ref>.md`   <!-- if applicable -->

## Changes
- [Notable change, grouped by intent]

## Test plan
- [Command or manual step to verify, with expected result]

## Review notes
- [Debatable tradeoff, accepted debt, area worth a close look]
```

- Only list what helps the reviewer: no file-by-file inventory, the diff
  already shows that.

## Creation and follow-up

1. `gh pr create --base main --title "…" --body "…" --label <labels>`.
2. Give the URL to the requester and restate the circuit: green CI, then a
   review on request (`/flux:review`) and its human triage, before
   merge. Never merge yourself.
3. On merge: if a spec is linked, set its frontmatter to
   `status: implemented` and update the `specs/README.md` index.

## After creation: watch CI and fix autonomously

Do not stop at "PR opened". A PR with red CI is not delivered.

1. `gh pr checks --watch --fail-fast` (fall back to polling `gh pr checks`
   if `--watch` is unavailable).
2. On failure: `gh run view <run-id> --log-failed`, but don't dump it
   whole into context. Grep it for the failing assertion or error line
   first; pull more of that step's log only if the grep hit isn't enough
   to diagnose the cause.
3. Fix the cause on the branch (never by weakening the gate or the test),
   let flux-gate validate locally, push. The checks re-run.
4. Loop until green. After 3 failed attempts on the same error, stop and
   report the diagnosis to the user instead of thrashing.
5. When green: nothing reviews the PR on its own, and there is no CI job
   to wait for. Tell the user the PR is ready and a review is one command
   away (`/flux:review`, run locally in a session). If you are driving
   the full cycle (feature skill) and they ask for it now, run that flow
   and chain into the triage flow of `gh-address-comments` in the same
   session. Either way the triage itself is human: review comments are
   never auto-addressed.
