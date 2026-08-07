---
name: flux-feature
description: The single entry point to build anything. Calibrates the process to the change (trivial, standard or full), then drives it end to end (spec, issue, implementation, gates, PR, CI, review triage). Only merging stays human. Use when the user asks to implement, fix or build something.
---

# Skill: flux-feature

## Purpose

One command from idea to a merge-ready PR. The skill calibrates the ceremony
to the size of the change, drives everything autonomously, and surfaces
exactly two human decisions along the way: the interview answers (full path
only) and the review triage.

## Step 1: Calibrate

Pick the lightest path that fits, announce it in one line, and proceed. The
user can override the choice at any time.

- **trivial**: typo, label, config tweak, a one-file fix with no behavior
  risk. No spec, no issue. Branch and fix.
- **standard**: a small, well-described feature or bug with a clear scope.
  No interview. Generate the GitHub issue directly from the user's
  description (gh-issue conventions); the issue is the contract.
- **full**: anything non-trivial or ambiguous. Run the spec-interview
  first; once the spec is validated, create the issue from it
  automatically (gh-issue conventions), without a separate invocation.

## Step 2: Build

1. Branch `feat/<ref>-<slug>` (or `fix/<slug>`) from an up-to-date default
   branch.
2. Implement, tests included. The flux-gate hooks run the gates on edits
   and on push; a red gate is the normal fix loop, never something to
   bypass.
3. Local verification: run the `qa` subagent whenever the change has
   observable user flows. Run the `reviewer` subagent per the risk rule
   (diff spanning many files or layers, schema or data migration,
   sensitive area, spec with many criteria); skip it for small contained
   changes. Rationale: `documentation/walkthrough.md`, step 5.
4. Conventional commits, `git push -u origin HEAD`.

## Step 3: PR and CI

1. Open the PR (gh-pr conventions: title, body from the real diff,
   `Closes #N` when an issue exists, spec link, test plan).
2. Watch CI and fix failures autonomously, capped at 3 attempts on the
   same error.

## Step 4: Review triage, in the same session

When CI is green, keep waiting: the automated review lands on the PR
within minutes (poll the PR comments). When it does, run the
gh-address-comments flow immediately: assess each finding against the
code, ask the user what to address in one question, fix the retained
items, reply on the comments, and bring CI back to green.

The triage is always human, never skipped. If the session ends before the
review lands, nothing is lost: `/flux:gh-address-comments` handles it
later.

## Step 5: Hand over

Report the PR URL, CI status and triage outcome. Merging belongs to the
user. Post-merge lifecycle (spec status flip, index update, branch
deletion) is automated by the repository workflows, not by you.

## Never

Merge, approve, bypass a gate, or address review comments without the
triage.
