---
name: gh-address-comments
description: "Triage and address review comments on the current branch's PR: the human picks what to fix, the agent fixes it autonomously. Use when the user asks to handle/address review comments on a PR."
---

# Skill: gh-address-comments

## Purpose

Turn PR review comments (automated or human) into fixes, with exactly one
human decision point: the triage. The human decides *what* deserves a fix;
the execution is autonomous.

## Step 1: Collect and assess

Run the `comment-triage` subagent for the current branch's PR. It fetches
top-level and inline comments, drops what's already resolved or addressed
by a later commit, and reads the actual code behind each remaining one to
form its own assessment. That reading is the expensive part; it happens in
the subagent's own context, not this session's. It returns a compact list:
comment, assessment, recommended keep/drop.

## Step 2: Triage (the human decision)

Present the subagent's list to the user: for each open comment, its
one-line summary and the assessment (agree/disagree/unclear, with why).

Then ask the user in ONE question (multiSelect) which findings to address.
Recommend a default selection based on the subagent's assessment. Do not
start fixing anything before this triage, even findings you are sure
about.

## Step 3: Fix (autonomous)

For each retained finding:

1. Fix the cause, tests included when the finding revealed a coverage gap.
2. Never weaken a gate, a test or the spec to satisfy a comment.
3. Conventional commits: one commit per logical fix, or one grouped
   `fix(review): …` commit for small related items.

Then push (flux-gate runs), and follow the CI watch loop from the `gh-pr`
skill until green.

## Step 4: Close the loop

1. Reply briefly on each addressed comment (what was done, commit sha) and
   on declined ones (why not, per the triage decision).
2. Report: what was fixed, what was declined and why, CI status. Nothing
   re-reviews on its own: run `/flux:review` again for a fresh pass on
   the new commits if one is wanted before merge, which stays with the
   human either way.
