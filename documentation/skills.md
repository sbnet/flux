# Skills and agents reference

Every skill is invocable as `/flux:<name>` once the plugin is installed.
Claude also invokes them on its own when the conversation matches their
purpose; the "When" sections below describe both triggers. Agents are not
invoked directly: Claude launches them as subagents when their conditions
apply, or when you ask.

Where each one sits in the cycle:

```
/flux:feature (single entry point, calibrates the path)
  └→ [spec-interview → gh-issue]  (full path only; standard: auto-issue;
      trivial: neither)
  └→ implementation + gates → qa / reviewer → gh-pr → CI
  └→ review (/flux:review, run locally, on demand) → triage (human, in-session) → human merge
      └→ post-merge: spec status + branch deletion, automated

init = one-time project setup       geo / ui-review / review = on demand
```

---

## init

**What.** Sets up flux in the current project: detects the stack, writes
`flux-config.yml`, installs the CI gate script (`.claude/hooks/flux-gate.sh`),
the GitHub workflows (gates CI + spec lifecycle), the `CLAUDE.md`
workflow contract, the specs index, and the GitHub labels. The PR review
is not a workflow: `/flux:review` runs locally, nothing to install for it.

**When.** Once per project, right after installing the plugin. Also safe to
re-run: it refreshes the managed files (e.g. after a plugin update that
changed `flux-gate.sh`).

**Reads.** The project tree (composer.json, package.json…) to infer lint /
static analysis / types / test / build commands.

**Produces.** `flux-config.yml`, `.claude/hooks/flux-gate.sh`,
`.github/workflows/{ci,spec-lifecycle}.yml`, `CLAUDE.md`,
`specs/README.md`. Also enables automatic head-branch deletion on the
repository. The spec-lifecycle workflow flips a merged PR's linked spec to
`status: implemented` and updates the index, deterministically.

**You still have to.** Review the inferred commands in `flux-config.yml`.

```
/flux:init
```

## spec-interview

**What.** Interviews you in depth about a feature (implementation, UX,
business rules, edge cases, tradeoffs), then writes one spec file per
feature: `specs/SPEC-<ref>.md` with a status frontmatter
(`draft → validated → implemented`), and maintains the `specs/README.md`
index.

**When.** At the start of any non-trivial feature, before any code.
Usually launched by the feature skill on its full path; invoke it directly to
write a spec without starting the build. The spec's acceptance criteria
become the contract that `qa`, `reviewer` and the PR review all check
against.

**Produces.** `specs/SPEC-<ref>.md` (`<ref>` = issue number or stable
slug), updated index. On your validation the status moves to `validated`
and the skill offers to chain into `/flux:gh-issue`.

```
/flux:spec-interview candidate management (CRUD)
```

## gh-issue

**What.** Writes and creates a GitHub issue (context, observable goal,
acceptance criteria, spec reference) with the project labels, and
back-links the issue number into the spec's frontmatter and index row.

**When.** Usually automatic: the feature skill creates the issue itself on its
standard and full paths. Invoke it standalone for bugs and tasks that need
tracking without building right away.

**Reads.** `flux-config.yml` (`github.labels`), the spec if one exists.

**Produces.** The GitHub issue (one issue = one deliverable; several if the
spec implies independent work streams), updated spec frontmatter.

```
/flux:gh-issue
```

## feature

**What.** The single entry point to build anything. Calibrates the path to
the change and announces it: **trivial** (no spec, no issue), **standard**
(issue auto-generated from your description), **full** (interview → spec →
auto-issue). Then drives everything: branch → implementation (tests
included) → gates → local verification (`qa` when there are user flows;
`reviewer` per the risk rule) → PR → CI watch-and-fix. Review is on
request, never automatic: it tells you how to launch one (`/flux:review`,
run locally) and runs the triage in the same session if you do. Stops only
for scope changes, destructive operations, or after 3 failed attempts on
one error.

**When.** Any "build / fix / implement X" request. This is the standard way
to work; the other skills remain available standalone. For the full
picture read the [walkthrough](walkthrough.md).

**Never does.** Merge, approve, bypass a gate, address review comments
without the human triage.

```
/flux:feature implement SPEC-candidate-management
```

## gh-pr

**What.** Opens the PR for the current branch: conventional-commit title,
body built from the real diff (summary, `Closes #N`, spec link, test plan,
review notes), then watches CI and fixes failures autonomously (3-attempt
cap per error). Ends by pointing you to `/flux:review` for a review
before the human triage.

**When.** Implementation done and pushed, either invoked by the feature skill
or standalone if you drove the implementation manually.

**Reads.** `git diff main...HEAD`, `flux-config.yml` (`github.labels`),
the linked issue/spec.

```
/flux:gh-pr
```

## gh-address-comments

**What.** The review-triage step. The `comment-triage` subagent collects
all PR comments (top-level and inline) and gives **its own assessment of
each finding** (it reads the code first and may disagree with the
reviewer); you pick what to address in one multi-choice question, then the
retained items are fixed autonomously and every comment gets a reply:
addressed (with commit) or declined (with your reason).

**When.** Inside a `/flux:feature` session, this flow runs as soon as a
review you requested (`/flux:review`) lands. Invoke it standalone when
the review arrived after your session ended. Either way the triage itself
is **always human**: it is the step that gives the merge decision its
substance.

```
/flux:gh-address-comments
```

## review

**What.** Reviews the current branch's PR (not a GitHub Actions job): the
`pr-review` subagent reads the real diff and the surrounding code, then
the findings get posted as comments on the PR, same shape as a human
reviewer would leave. Nothing reviews a PR on its own, so this is the only
way to get one, and also how you ask for another pass after further
changes.

**When.** Any time a review is wanted: once CI is green and before
merging, or again after addressing comments.

```
/flux:review
```

## geo

**What.** Audits and improves visibility in generative engines (AI answers,
LLM-powered search), in strict order: renderability (what a no-JS crawler
sees; an SPA shell is invisible), machine surface (`llms.txt`, robots
rules for AI crawlers, server-side JSON-LD), then content citability
(self-contained answers, question-phrased headings, dated facts).

**When.** The project has public pages and you care about being cited by
AI assistants. Complementary to a classic SEO pass: meta, sitemap and
Core Web Vitals are not its job.

```
/flux:geo audit the public pages
```

## ui-review

**What.** Reviews the interface as a user experiences it: drives the
running app with playwright-cli, then checks form ergonomics, pattern
consistency, and flow friction against the spec. Report ordered blocking >
confusing > polish. Two depths: **quick** (default) screenshots each page
at 1440 and 375, normal state only; **deep** (ask for it, e.g. "deep
review", or when quick turns up something breakpoint/state-specific) adds
768 and the full state matrix (empty / loading / error / overflow).

**When.** A feature's UI is functional and you want a design pass; before
a demo; or periodically on the main flows. Complementary to the
accessibility skill (full WCAG) and frontend-design (building new UI).

```
/flux:ui-review the candidates pages
/flux:ui-review deep review of the candidates pages
```

---

## Agents

### reviewer

Pre-PR review of the branch diff: logic, architecture, security, spec
conformance, never what the gates already enforce. **Conditional by
design**: run it when a post-PR finding would be expensive: diff spanning
many files/layers, schema or data migration, sensitive area (auth,
payments, permissions, files), spec with many criteria. Skip it for small
contained changes: the PR review (`/flux:review`) covers those.
Rationale and a worked example: [walkthrough](walkthrough.md), part 2
step 5.

### qa

Runs the app for real and walks the spec's user flows (curl, or
playwright-cli when the flow needs a browser), cleans up after itself, and
reports pass/fail per acceptance criterion with reproduction commands.
**Unconditional** whenever the feature has observable flows; nothing else
in the cycle actually runs the app. Two depths: **quick** (default) walks
the happy path only; **deep** also probes unhappy paths (invalid input,
missing auth, empty states, double submission), triggered by asking for
it or when the flow touches auth, payments, permissions, or a mutation
with no automated coverage for its unhappy path.

### pr-review

Reads an open PR's diff and the surrounding code, and reports findings
(logic, architecture, security, spec conformance) for the `review` skill
to post as PR comments. Launched by `/flux:review`; not invoked directly.

### comment-triage

Collects a PR's review comments, drops what's already resolved or
addressed, and assesses each remaining one against the actual code
(agree/disagree/unclear, with why). Launched by `/flux:gh-address-comments`
to prepare the human triage; not invoked directly.
