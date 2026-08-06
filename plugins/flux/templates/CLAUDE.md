# Flux-managed project

This project is driven by [flux](https://github.com/sbnet/flux):
`flux-config.yml` declares the commands and quality gates; the flux-gate
hooks enforce them on edits and pushes.

## Workflow contract

- **Be autonomous through the delivery cycle.** When an implementation is
  done, do not stop and wait: run the gates, commit (conventional commits),
  push, open the PR (`gh-pr` skill conventions), then watch CI and fix
  failures until green. The `flux-feature` skill describes the full cycle.
- **The only human step is merging the PR.** Never merge; never approve
  reviews. Everything else, including fixing red CI on an open PR, is
  yours to carry without asking.
- **Never bypass a gate.** No `--no-verify`, no weakening a test or a
  config to get to green. If a gate blocks, fix the cause.
- Ask only for: scope changes not covered by the spec, destructive
  operations, or after 3 failed attempts at the same error.
- **Review comments are triaged by the human, never auto-addressed.**
  When a review lands on a PR, the user reads it and runs
  `/gh-address-comments`; the agent assesses each finding, the user picks,
  the agent fixes what was retained.

## Conventions

- Features start from a spec (`specs/SPEC-<ref>.md`, `/spec-interview`)
  and a GitHub issue (`/gh-issue`) for anything non-trivial.
- Branches: `feat/<ref>-<slug>`, `fix/<slug>`.
- All committed content (code, comments, commits, PRs, issues) in English.
