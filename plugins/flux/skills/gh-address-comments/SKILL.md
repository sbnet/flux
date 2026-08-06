---
name: gh-address-comments
description: Triage and address review comments on the current branch's PR — human picks what to fix, the agent fixes it autonomously. Use when the user asks to handle/address review comments on a PR.
---

# Skill: gh-address-comments

## Purpose

Turn PR review comments (automated or human) into fixes, with exactly one
human decision point: the triage. The human decides *what* deserves a fix;
the execution is autonomous.

## Step 1 — Collect

1. Find the PR for the current branch: `gh pr view --json number,url`.
2. Fetch all comments: top-level (`gh pr view --comments`) and inline
   (`gh api repos/{owner}/{repo}/pulls/<n>/comments`).
3. Ignore comments already resolved or already addressed by a later commit
   (check the diff since the comment's commit).

## Step 2 — Triage (the human decision)

For each open finding, present:

- a one-line summary of the comment;
- **your own assessment**: agree (and why), disagree (and why), or unclear —
  read the actual code before judging, never assess from the comment alone.

Then ask the user in ONE question (multiSelect) which findings to address.
Recommend a default selection based on your assessment. Do not start fixing
anything before this triage — even findings you are sure about.

## Step 3 — Fix (autonomous)

For each retained finding:

1. Fix the cause, tests included when the finding revealed a coverage gap.
2. Never weaken a gate, a test or the spec to satisfy a comment.
3. Conventional commits — one commit per logical fix, or one grouped
   `fix(review): …` commit for small related items.

Then push (flux-gate runs), and follow the CI watch loop from the `gh-pr`
skill until green.

## Step 4 — Close the loop

1. Reply briefly on each addressed comment (what was done, commit sha) and
   on declined ones (why not, per the triage decision).
2. Report: what was fixed, what was declined and why, CI status. The PR is
   back to waiting for review — automated review re-runs on the new push;
   merging stays with the human.
