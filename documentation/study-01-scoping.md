# Flux — Scoping study (phase 1)

Point-by-point analysis of the initial ideas, followed by a starting plan.
Cross-cutting goal: **reuse the native primitives of Claude Code and GitHub**
(hooks, skills, subagents, branch protection, Actions) rather than building a
home-grown orchestrator. Flux is a *convention and configuration layer*, not a
new engine.

---

## 1. Hooks for sensitive steps (tests, lint…)

**What Claude Code offers natively.** Hooks (`.claude/settings.json`) fire on
precise events: `PostToolUse` (after an Edit/Write), `PreToolUse` (before a
Bash call, with a matcher on the command), `Stop` (when the agent wants to end
its turn). A hook exiting with code 2 **blocks** the action and feeds its
message back to the agent, which then fixes the problem on its own. This is
exactly the mechanism we want: the "the agent cannot move on until it's green"
loop is native.

**Watch out for.**
- Running the whole test suite after every edit is too slow and costly. Good
  split: lint/format in `PostToolUse` (fast), test suite in `PreToolUse` on
  `git commit`/`git push` and/or in `Stop`.
- Hooks are **local and bypassable** (the agent or the human can disable
  them). They are the first line of defense, not the guarantee — see §2.
- Commands (lint, test) vary per project → they must come from
  `flux-config.yml` (§6); the hook script reads them.

**Proposed decision.** One generic hook script (`flux-gate.sh`) driven by the
config, rather than one hook per tool.

---

## 2. Production blocked by the sensitive steps

**The real blocking cannot rely on hooks** (they are local). The source of
truth must live on the GitHub side:

- **GitHub Actions**: CI workflow replaying lint + tests + build.
- **Branch protection on `main`**: required status checks (CI must be green)
  + no direct pushes.
- **GitHub Environments**: a `production` environment with *required
  reviewers* = deployment waits for an explicit human validation, even when
  everything is green.

**Two lines of defense.**
1. Local hooks: immediate feedback to the agent, fixes before even pushing.
2. CI + branch protection: unbypassable guarantee, even if hooks are skipped.

Nothing to invent here: this is standard GitHub configuration, which Flux can
ship as workflow templates.

---

## 3. Skills

Current state: most of the foundation already exists.

| Expressed need | Existing | Missing |
|---|---|---|
| SEO / GEO / accessibility | `seo` + `accessibility` skills | GEO (Generative Engine Optimization) to add to the `seo` skill |
| Frontend UI/UX | `frontend-design` skill | nothing blocking |
| Spec definition | `spec-interview` skill | multi-spec management (see below) |
| GitHub issues | — (`gh-address-comments`, `gh-fix-ci` cover downstream) | `gh-issue` skill (creation/writing) |
| PR writing | — | `gh-pr` skill |

**Specs skill rework (the real work item).**
- Output to `specs/SPEC-<ref>.md` instead of a single overwritten `SPEC.md`.
- `<ref>` = slug or GitHub issue number (natural link with §gh-issue).
- Minimal frontmatter: status (draft / validated / implemented), linked
  issue, date.
- A `specs/README.md` index generated/maintained by the skill.

**`gh-issue` and `gh-pr` skills.** Thin: a template + the project
conventions (labels, title format, spec link). They complete the existing
chain: `gh-issue` → `gh-pr` → `gh-fix-ci` → `gh-address-comments` = the full
life cycle of a contribution.

**Anti-scattering.** Do not rewrite existing skills; the three work items
are: specs rework, `gh-issue`, `gh-pr`. GEO and UI/UX are comfort
improvements, not foundations.

---

## 4. Automated review + merge blocked until human validation

Two independent mechanisms, both native to GitHub:

- **Automated review**: `claude-code-action` (official GitHub Action) on
  `pull_request` → the agent posts a review as comments. One-off
  alternative: `/code-review ultra <PR#>` from Claude Code. The agent
  **never approves** — it comments.
- **Merge blocking**: branch protection = *require 1 approving review*
  (human, since the agent doesn't approve) + *required status checks*.
  `CODEOWNERS` if a specific human must validate.

Result: merging is physically impossible without a human, whatever the
quality of the automated review. No code to write, only configuration + one
workflow.

---

## 5. Multi-agent

**What exists**: subagents (`.claude/agents/*.md`) — the project already has
a `security-reviewer`. A subagent = a role with its instructions, allowed
tools, optionally its model.

**Recommendation: start small.** The general experience with multi-agent
systems: value comes from 2-3 well-defined roles, not a swarm. Candidate
roles for Flux v1:
- `reviewer` (quality/architecture — complements `security-reviewer`);
- `qa` (runs the app, checks real behavior, not just tests).

Orchestration stays in the main Claude Code session. More ambitious patterns
(parallel planner/implementer agents, scheduled cloud agents) are
**explicitly out of scope for v1** — that's the first scattering trap.

---

## 6. `flux-config.yml`

**Important fact**: Claude Code does not natively read an arbitrary config
file. `flux-config.yml` is a convention of *our* layer: the hook scripts and
the flux skills read it.

Deliberately minimal v1 schema: see
[flux-config.example.yml](flux-config.example.yml) (annotated reference).
A key is only added once a consumer (hook or skill) needs it. `yq` (or a
small parser) is a dependency of the hook scripts.

---

## 7. Packaging (cross-cutting question, unlisted but structural)

Two options to distribute Flux across projects:

1. **Template `.claude/` directory** copied into each project — simple, but
   updates propagate poorly.
2. **Claude Code plugin** (skills + hooks + agents + commands packaged,
   installable from a git marketplace) — the right vehicle eventually.

**Proposed decision**: develop first *in this repo* as a regular `.claude/`
(fast iteration), and convert to a plugin at the end of v1, when the
interfaces (config, skill names) are stable.

---

## Stack decisions (settled on 2026-08-06)

- **Forge: GitHub** for v1. The whole chain relies on the `gh` CLI,
  `claude-code-action`, branch protection and Environments. We still set
  `forge: github` in `flux-config.yml` from day one: skills go through this
  indirection, keeping a Gitea/Forgejo port possible in v2 without a
  rewrite.
- **Pilot: Laravel / Vue / Inertia.** Monolith = one repo, one gate config:
  `pint` (lint), `larastan` (static analysis), `pest` (tests), `vite build`.
  Inertia avoids managing a separate API.
- **Second pilot (phase 4)**: Next.js, to prove `flux-config.yml` is generic
  across a different toolchain.

---

## Starting plan (without scattering)

One principle: **each phase ends with a demonstration on a real pilot
project**. No next phase until the demo passes.

### Phase 0 — Foundation (short)
- Freeze the v1 schema of `flux-config.yml` (§6).
- Choose the pilot project and drop a config in it.
- **Demo: `yq` reads the config from a script.**

### Phase 1 — Guardrails (the core of the value)
- Generic hook script driven by the config: lint on `PostToolUse`, tests on
  `PreToolUse` for `git push`.
- CI workflow template + branch protection on the pilot.
- **Demo: the agent introduces a lint error → blocked → fixes it on its
  own; a push with red tests is refused locally AND by CI.**

### Phase 2 — Spec → issue → PR cycle
- Specs skill rework (`SPEC-<ref>.md` + index).
- `gh-issue` and `gh-pr` skills.
- **Demo: a feature starts from a spec interview and ends as a properly
  written PR linked to its issue.**

### Phase 3 — Review and human gate
- `claude-code-action` review workflow on PRs.
- Branch protection: human approval required + `production` environment
  with a required reviewer.
- **Demo: a PR receives an agent review; merging is impossible without
  human approval; deployment waits for validation.**

### Phase 4 — Extension (only if 1-3 hold)
- `reviewer` / `qa` subagents (§5).
- GEO part of the `seo` skill, UI/UX improvements.
- Conversion into a Claude Code plugin (§7).

### Out of scope for v1 (deliberate anti-scattering list)
- Parallel multi-agent orchestrator, scheduled cloud agents.
- Dashboard / monitoring UI.
- Support for forges other than GitHub.
- Multi-language generalization of the config beyond the pilot's needs.

---

## Status log

- **2026-08-06 — Phases 0, 1 and 2 delivered** on the pilot
  (github.com/sbnet/ats, private): flux-config posed, flux-gate hook wired
  and demonstrated, CI green, skills installed. Branch protection is
  **waived in v1** (GitHub Free + private repo does not allow it); the human
  gate remains a discipline until the repo goes public or Pro.
- **2026-08-06 — Phases 2 and 3 validated end to end** on the first real
  feature (PR #3, candidate CRUD): spec → issue → PR → gates → automated
  review (2 real logic findings) → human merge. First-run feedback led to
  three fixes: the `flux-feature` skill (autonomous cycle, human only
  merges), a CI watch-and-fix loop in `gh-pr`, and a human-triage flow in
  `gh-address-comments` (review comments are never auto-addressed).
  CI pitfall fixed on the way: assets must build **before** the gates
  (Inertia tests need the Vite manifest).
