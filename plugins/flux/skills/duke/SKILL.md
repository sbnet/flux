---
name: duke
description: "Unattended mode that chains full delivery cycles over the open flux issues: build, PR, CI, review, automatic triage, merge, next. Only when the user explicitly invokes /flux:duke and types the confirmation phrase; never enter it from any other request."
disable-model-invocation: true
---

# Skill: duke

## Purpose

Run through a fully written backlog without stopping: for each open flux
issue, build it, open the PR, get CI green, review it, triage and fix the
findings, merge, move on. This is the only place in flux where the agent
merges and triages on its own. That exception is why entry is guarded
and why any doubt ends the session. Spec: `specs/SPEC-duke-mode.md` in
the flux repository.

## Scope of the exception

Duke mode exists only between a typed confirmation and the end of the
current session. It is never entered implicitly: a request like "do
everything" or "finish the backlog" is not an invocation, point the user
to `/flux:duke` instead. Outside a confirmed duke session, the usual
rules apply unchanged: never merge, never address comments without the
human triage. Gates are never bypassed, in duke mode or anywhere.

## Settings

Read the `duke:` section of `flux-config.yml`, with these defaults when
absent:

- `max_issues`: 5. An argument (`/flux:duke 3`) overrides it.
- `merge_method`: `squash` (`squash`, `merge` or `rebase`).
- `sensitive_paths`: `database/migrations/**`, `**/auth/**`,
  `**/*payment*`.

## Step 1: Entry checks

Check everything, then report every failure at once. If any check fails,
refuse entry, list each offending item and what it is missing, and stop
without asking for confirmation and without modifying anything.

1. **Clean start.** Working tree clean; default branch checked out and
   up to date with its remote (`git fetch`, then no divergence).
2. **Nothing in flight.** No open PR from a `feat/*` or `fix/*` branch
   (`gh pr list --state open`); no open flux issue with an assignee or an
   in-progress label.
3. **CI exists.** The repository has at least one workflow running on
   pull requests; otherwise the "CI green" guard can never be met.
4. **Backlog complete.** Take the open issues carrying the
   `github.labels` labels (`gh issue list --label … --state open --json
   number,title,body,assignees,labels`). There must be at least one.
   Each one must have an "Acceptance criteria" section with at least
   one checkbox. Each non-trivial one must reference a
   `specs/SPEC-<ref>.md` that exists with `status: validated`.
5. **Dependencies resolvable.** An issue body saying `Depends on #M`
   with #M open and outside the plan is excluded from the plan and
   listed as such (this alone does not refuse entry).

## Step 2: Plan and confirmation

1. Build the plan: eligible issues in ascending number order, dependents
   after what they depend on, capped at `max_issues`. Mention how many
   eligible issues are left beyond the cap.
2. Show it: the issues in order (number, title, spec), the merge method,
   the sensitive paths, and plainly: "Duke will merge PRs and triage
   review findings without asking. It stops the whole session at the
   first failed guard."
3. Ask the user to type exactly `I am the duke`, as plain text in chat
   (not a multiple-choice question). Any other answer, "yes" included,
   cancels: say so and stop.
4. The plan is fixed from this point: issues created later are not
   picked up.

## Step 3: The loop, per issue

1. Update the default branch; branch `feat/<N>-<slug>` from it.
2. Implement with tests, as in the `feature` skill step 2. A red gate is
   the fix loop, never something to bypass.
3. Local verification: the `qa` subagent when the issue has observable
   user flows; the `reviewer` subagent per the usual risk rule.
4. Conventional commits, `git push -u origin HEAD`, open the PR with the
   gh-pr conventions (`Closes #N`, spec link, test plan listing every
   acceptance criterion).
5. Watch CI and fix failures, capped at 3 attempts on the same error.
6. Run the review flow: the `pr-review` subagent, findings posted as PR
   comments as in the `review` skill.
7. Automatic triage: run the `comment-triage` subagent. Fix every
   finding it assesses as valid (gh-address-comments step 3), then reply
   on every comment: fixed with the commit sha, or dismissed with the
   reason. Push and bring CI back to green.
8. Merge guard, all required:
   - every CI check green on the PR's head commit;
   - no `blocking` finding left unfixed, and none whose assessment is
     unclear;
   - every acceptance criterion of the issue and spec verified and
     ticked in the PR body;
   - no changed file matches `sensitive_paths`, and by judgment the diff
     touches no schema migration, authentication, authorization,
     payments or data deletion.
9. Merge: `gh pr merge <number> --<merge_method> --delete-branch`. Never
   `--admin`, never approve the PR. Confirm the issue closed; close it
   with a link to the PR if the forge did not.
10. Next issue in the plan.

## Step 4: Stop, never skip

Any of these ends duke mode for the whole session, immediately:

- a failed merge guard;
- 3 failed attempts on the same error;
- a merge conflict, or `gh pr merge` refused (branch protection
  requiring an approval, for instance);
- a scope ambiguity the issue and spec do not settle.

Leave the current PR open, post a PR comment stating why duke stopped
and what a human needs to look at, then report (step 5). Do not move on
to other issues: later work would build on a base nobody has checked.

When the user says stop, finish the current atomic step (a commit, a
push, a comment reply), start nothing new, and report.

## Step 5: Report

On every exit (backlog done, cap reached, stop, interruption), report:

- merged PRs and closed issues, in order;
- per PR, the findings fixed and dismissed (with reasons);
- on a stop: the blocking reason, the PR left open, and its URL;
- the eligible issues not reached.

Then state that duke mode is over. Re-entering needs a new `/flux:duke`
and a new confirmation, in this session or any other.

## Never

Enter without the typed confirmation, carry the mode into another
session, skip a failing issue to continue, approve a PR, merge with
`--admin`, merge a PR touching a sensitive area, or bypass a gate.
