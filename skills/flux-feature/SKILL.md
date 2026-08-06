---
name: flux-feature
description: Drive a feature end to end autonomously — from validated spec/issue to a green PR awaiting human review. Use when the user asks to implement a feature, an issue, or a spec. Stops only at merge, which is always a human decision.
---

# Skill: flux-feature

## Purpose

Carry a feature through the whole flux cycle without stopping between steps:
branch → implement → gates → commit → push → PR → green CI. The only step
that belongs to a human is merging the PR.

## Autonomy contract

- Do NOT stop to ask "should I commit / push / open the PR?" — that is what
  this skill is for. Chain the steps.
- Stop and ask ONLY for: scope changes (the spec doesn't cover a decision
  that changes the deliverable), destructive operations, or after 3 failed
  attempts at fixing the same gate/CI error.
- Never merge the PR. Never bypass flux-gate or force-push over failures.

## Steps

1. **Anchor the work.** Find the spec (`specs/SPEC-<ref>.md`) and/or the
   GitHub issue. If neither exists, offer `/spec-interview` first for
   non-trivial features; for trivial fixes, proceed with the issue text or
   the user's description.
2. **Branch.** `git switch -c feat/<ref>-<slug>` (or `fix/…`) from an
   up-to-date default branch.
3. **Implement.** Follow the spec's acceptance criteria. Write or update
   tests as part of the implementation, not after the PR.
4. **Gates.** The flux-gate hooks run automatically on edits and on push.
   If a gate blocks, fix it and continue — that is the normal loop.
5. **Commit and push.** Conventional commits, atomic where reasonable.
   `git push -u origin HEAD`.
6. **Open the PR.** Apply the `gh-pr` skill conventions (title, body built
   from the real diff, `Closes #N`, test plan).
7. **Watch CI and fix.** Follow the "After creation" section of `gh-pr`:
   watch checks, diagnose failures, fix, push again — loop until green or
   3 attempts on the same error.
8. **Report.** Give the user the PR URL, CI status, spec/issue links, and
   anything left open. The PR now waits for automated + human review.
   Point the user to the automated review once posted: they read it, then
   run `/gh-address-comments` — triage is theirs, fixing is autonomous.
