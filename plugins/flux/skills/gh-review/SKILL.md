---
name: gh-review
description: "Trigger the automated GitHub review for the current branch's PR on demand, instead of waiting for it to fire on push. Use when the user asks to run/launch/trigger the review manually, especially when github.auto_review is false in flux-config.yml."
---

# Skill: gh-review

## Purpose

Launch the `claude-review` GitHub Actions workflow for the current PR by
hand, via `workflow_dispatch`. This is what `github.auto_review: false` in
`flux-config.yml` leaves you with once the workflow no longer fires on
every push: a way to ask for the review only when you actually want it,
which matters since each run has a real cost.

Works regardless of the `auto_review` setting: it can also be used to
re-review a PR that already got its automatic pass, after further changes.

## Preconditions

1. Find the PR for the current branch: `gh pr view --json number,url`.
   If there is none, tell the user to open one first (`/flux:gh-pr`).
2. Everything meant to be reviewed must already be pushed: the workflow
   reviews the PR's current head commit on GitHub, not local changes.

## Run

```shell
gh workflow run claude-review.yml -f pr_number=<number>
```

Then locate and watch the run:

```shell
gh run list --workflow=claude-review.yml --limit 1
gh run watch <run-id>
```

Report the run URL to the user. The review posts as the same sticky
comment on the PR as the automatic path: read it and continue with
`/flux:gh-address-comments` when it lands.
