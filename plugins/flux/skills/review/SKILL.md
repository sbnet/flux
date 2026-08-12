---
name: review
description: "Review the current branch's PR, in this session, and post the findings as comments on it. Use when the user asks to run/launch/trigger a review, or the feature/gh-pr flow reaches the point where CI is green and a review is worth requesting before merge."
---

# Skill: review

## Purpose

Review the current branch's PR the way a human reviewer would, right in
this session, and post the findings on the PR itself: one summary comment
plus inline comments on specific lines. There is no CI-based review to
wait for or trigger: this is the only way to get one, run locally by the
user whenever a pass is actually wanted, typically once CI is green and
before merging.

## Preconditions

1. Find the PR for the current branch: `gh pr view --json number,url,headRefOid`.
   If there is none, tell the user to open one first (`/flux:gh-pr`).
2. Everything meant to be reviewed must already be pushed: review the
   PR's head commit (`headRefOid`), not uncommitted local changes.

## Step 1: Review

Work from the actual diff (`gh pr diff <number>`), not from memory. Style,
static analysis, types and tests are already enforced by the gates; do
not re-check them. Focus on what they miss:

- logic errors and edge cases
- architecture and design fit with the existing codebase
- security implications
- spec conformance: if the PR references a spec (`specs/SPEC-*.md`),
  verify the acceptance criteria are covered one by one
- test coverage gaps (missing cases, not missing runs)

Read the surrounding code before judging a finding, never assess from the
diff alone.

## Step 2: Post

1. **Summary comment.** Look for an existing PR comment containing the
   `<!-- flux-review -->` marker (`gh pr view <number> --json comments`).
   If found, edit it in place so repeated runs update one comment instead
   of piling up:
   ```shell
   gh api -X PATCH repos/{owner}/{repo}/issues/comments/<comment-id> -f body="<!-- flux-review -->
   …"
   ```
   Otherwise create it: `gh pr comment <number> --body "<!-- flux-review -->
   …"`.
2. **Inline comments**, one per finding tied to a specific line:
   ```shell
   gh api repos/{owner}/{repo}/pulls/<number>/comments \
     -f body="…" -f commit_id="<headRefOid>" -f path="<file>" \
     -F line=<n> -f side=RIGHT
   ```
3. Never approve the PR, never submit the review as a chat message
   instead of a comment: the comments on the PR are the deliverable.
   Merging stays with the human.

Report the comment URLs to the user, then continue with
`/flux:gh-address-comments` for the triage.
